import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../key_generator.dart';
import '../key_parser.dart';
import 'io.dart';
import 'local_keys.dart';
import 'merge.dart';

const keysOutputPath = 'lib/generated/localino_keys.dart';

/// Exit codes shared by the CLI and the MCP server.
abstract final class SyncExit {
  static const ok = 0;
  static const error = 1;
  static const conflict = 3;
  static const auth = 4;
  static const network = 5;
}

class SyncException implements Exception {
  final int exitCode;
  final String message;

  const SyncException(this.exitCode, this.message);

  @override
  String toString() => message;
}

/// Outcome of `status` / `pull` / `push` / `sync`. Never contains the write key.
class SyncResult {
  final String command;
  final bool dryRun;

  /// False when the remote could not be reached (`status` offline).
  final bool remoteKnown;
  final Map<KeyState, int> counts;

  /// Keys that are not `unchanged`.
  final List<KeyDiff> changes;

  /// Keys whose local value was (or would be) replaced from the remote.
  final List<KeyDiff> pulled;

  /// `{locale, key, ts}` the server applied (dry run: would apply, `ts` null).
  final List<Map<String, dynamic>> pushed;
  final List<Map<String, dynamic>> rejectedLocked;

  /// Conflicts that stopped the run.
  final List<Map<String, dynamic>> conflicts;

  /// `{locale, key, local_value, remote_type}` whose value shape the key's Localino type
  /// rejects; they stopped the run.
  final List<Map<String, dynamic>> typeMismatches;

  /// `{locale, key, reason}` the API would reject (`invalid_key`, `unsupported_value`,
  /// `mixed_shapes`); they stopped the run.
  final List<Map<String, dynamic>> invalid;
  final List<KeyDiff> skippedDeletes;

  /// Local locale files Localino does not have; skipped.
  final List<String> unknownLocales;

  /// Locales created in Localino (dry run: that would be) for local files it lacked.
  final List<String> addedLocales;

  /// Locale files were rewritten — project codegen should run.
  final bool localFilesChanged;

  /// Set when `lib/generated/localino_keys.dart` was regenerated.
  final String? generatedKeys;

  const SyncResult({
    required this.command,
    this.dryRun = false,
    this.remoteKnown = true,
    this.counts = const {},
    this.changes = const [],
    this.pulled = const [],
    this.pushed = const [],
    this.rejectedLocked = const [],
    this.conflicts = const [],
    this.typeMismatches = const [],
    this.invalid = const [],
    this.skippedDeletes = const [],
    this.unknownLocales = const [],
    this.addedLocales = const [],
    this.localFilesChanged = false,
    this.generatedKeys,
  });

  int get exitCode {
    if (invalid.isNotEmpty) {
      return SyncExit.error;
    }

    return conflicts.isEmpty && typeMismatches.isEmpty
        ? SyncExit.ok
        : SyncExit.conflict;
  }

  SyncResult copyWith({
    String? command,
    List<KeyDiff>? pulled,
    List<Map<String, dynamic>>? pushed,
    List<Map<String, dynamic>>? rejectedLocked,
    List<Map<String, dynamic>>? conflicts,
    List<Map<String, dynamic>>? typeMismatches,
    List<Map<String, dynamic>>? invalid,
    List<KeyDiff>? skippedDeletes,
    List<String>? addedLocales,
    bool? localFilesChanged,
    String? generatedKeys,
  }) => SyncResult(
    command: command ?? this.command,
    dryRun: dryRun,
    remoteKnown: remoteKnown,
    counts: counts,
    changes: changes,
    pulled: pulled ?? this.pulled,
    pushed: pushed ?? this.pushed,
    rejectedLocked: rejectedLocked ?? this.rejectedLocked,
    conflicts: conflicts ?? this.conflicts,
    typeMismatches: typeMismatches ?? this.typeMismatches,
    invalid: invalid ?? this.invalid,
    skippedDeletes: skippedDeletes ?? this.skippedDeletes,
    unknownLocales: unknownLocales,
    addedLocales: addedLocales ?? this.addedLocales,
    localFilesChanged: localFilesChanged ?? this.localFilesChanged,
    generatedKeys: generatedKeys ?? this.generatedKeys,
  );

  Map<String, dynamic> toJson() => {
    'command': command,
    'dry_run': dryRun,
    'remote_known': remoteKnown,
    'counts': {for (final entry in counts.entries) entry.key.name: entry.value},
    'changes': [for (final diff in changes) diff.toJson()],
    'pulled': [for (final diff in pulled) diff.toJson()],
    'pushed': pushed,
    'rejected_locked': rejectedLocked,
    'conflicts': conflicts,
    'type_mismatches': typeMismatches,
    'invalid': invalid,
    'skipped_deletes': [for (final diff in skippedDeletes) diff.toJson()],
    'unknown_locales': unknownLocales,
    'added_locales': addedLocales,
    'local_files_changed': localFilesChanged,
    if (generatedKeys != null) 'generated_keys': generatedKeys,
  };
}

class _Snapshot {
  final List<String> locales;

  /// Key → Localino `type` (`text`, `list`, `map`, `plural`, …).
  final Map<String, String> keyTypes;
  final Map<String, Map<String, RemoteEntry>> translations;

  const _Snapshot(this.locales, this.keyTypes, this.translations);
}

/// Local locale files (by locale), their parsed values, the lock, and locales Localino lacks.
typedef _State =
    ({
      Map<String, LocaleFile> files,
      Map<String, Map<String, dynamic>> local,
      Lock lock,
      List<String> unknownLocales,
    });

/// Bidirectional sync between local locale files, `.localino/lock.json` and Localino.
/// Returns results; never prints. Files and lock are written only after the remote call
/// they depend on succeeded.
class SyncEngine {
  final LocalinoConfig config;
  final http.Client client;
  final Uri apiUrl;
  final Map<String, String> env;
  final String? credentialsPath;
  final Duration timeout;

  SyncEngine({
    required this.config,
    required this.client,
    required this.apiUrl,
    this.env = const {},
    this.credentialsPath,
    this.timeout = const Duration(seconds: 15),
  });

  String get _root => config.root;

  File get _lockFile => File('$_root/$lockPath');

  File localeFile(String locale) =>
      File('$_root/${config.asset.replaceFirst('{locale}', locale)}');

  /// Locales with a file matching the asset pattern (`setup.json` excluded).
  List<String> localLocales() {
    final pattern = File('$_root/${config.asset}');
    final name = pattern.uri.pathSegments.last;
    final parts = name.split('{locale}');

    if (parts.length != 2 || !pattern.parent.existsSync()) {
      return [];
    }

    final matcher = RegExp(
      '^${RegExp.escape(parts.first)}(.+)${RegExp.escape(parts.last)}\$',
    );

    return [
      for (final entity in pattern.parent.listSync().whereType<File>())
        if (matcher.firstMatch(entity.uri.pathSegments.last)?.group(1)
            case final locale?)
          if (locale != 'setup') locale,
    ]..sort();
  }

  Future<SyncResult> status() async {
    _Snapshot? snapshot;

    try {
      snapshot = await _snapshot();
    } on SyncException catch (e) {
      if (e.exitCode != SyncExit.network) rethrow;
    }

    final state = _load(snapshot);
    final diffs = classify(
      local: state.local,
      lock: state.lock,
      remote: snapshot?.translations,
    );

    return SyncResult(
      command: 'status',
      remoteKnown: snapshot != null,
      counts: countStates(diffs),
      changes: diffs.where((e) => e.state != KeyState.unchanged).toList(),
      unknownLocales: state.unknownLocales,
    );
  }

  Future<SyncResult> pull({
    Prefer? prefer,
    bool dryRun = false,
    Set<String>? keys,
  }) async =>
      _pull(await _snapshot(), prefer: prefer, dryRun: dryRun, keys: keys);

  /// With [addLocales], local locale files Localino lacks are created there first (a dry run
  /// only lists them; their keys are pushed once the locales exist).
  Future<SyncResult> push({
    Prefer? prefer,
    bool dryRun = false,
    bool prune = false,
    Set<String>? keys,
    bool addLocales = false,
  }) async {
    final writeKey = _writeKey();
    var snapshot = await _snapshot();
    final missing = addLocales ? _missingLocales(snapshot) : const <String>[];

    if (missing.isNotEmpty) {
      // Anything the push would reject in the new locales stops the run before a locale is created.
      final preview = _planPush(
        _withLocales(snapshot, missing),
        prefer: prefer,
        prune: prune,
        keys: keys,
      );

      if (preview.plan.blocked) {
        return _blocked('push', snapshot, preview, dryRun: dryRun);
      }
    }

    final added =
        missing.isEmpty
            ? const <String>[]
            : await _addLocales(writeKey, missing, dryRun: dryRun);

    if (added.isNotEmpty && !dryRun) {
      snapshot = await _snapshot();
    }

    final result = await _push(
      writeKey,
      snapshot,
      prefer: prefer,
      dryRun: dryRun,
      prune: prune,
      keys: keys,
    );

    return result.copyWith(addedLocales: added);
  }

  /// Pull, then push — both against one snapshot (a pull never changes Localino).
  /// Anything the push would reject is found before the pull writes, so it leaves both
  /// sides untouched. A push failure after a successful pull keeps the pull applied.
  Future<SyncResult> sync({
    Prefer? prefer,
    bool prune = false,
    bool addLocales = false,
  }) async {
    final writeKey = _writeKey();
    var snapshot = await _snapshot();
    final missing = addLocales ? _missingLocales(snapshot) : const <String>[];
    final preview = _planPush(
      _withLocales(snapshot, missing),
      prefer: prefer,
      prune: prune,
    );

    if (preview.plan.typeMismatches.isNotEmpty ||
        preview.plan.invalid.isNotEmpty) {
      return _blocked('sync', snapshot, preview);
    }

    final added =
        missing.isEmpty
            ? const <String>[]
            : await _addLocales(writeKey, missing, dryRun: false);

    if (added.isNotEmpty) {
      snapshot = await _snapshot();
    }

    final pulled = (await _pull(
      snapshot,
      prefer: prefer,
    )).copyWith(addedLocales: added);

    if (pulled.conflicts.isNotEmpty) {
      return pulled.copyWith(command: 'sync');
    }

    final SyncResult pushed;

    try {
      pushed = await _push(writeKey, snapshot, prefer: prefer, prune: prune);
    } on SyncException catch (e) {
      final next =
          e.exitCode == SyncExit.network
              ? 'push pending — re-run `sync`'
              : 'push failed';
      throw SyncException(
        e.exitCode,
        'Pulled ${pulled.pulled.length} keys; $next. ${e.message}',
      );
    }

    return pulled.copyWith(
      command: 'sync',
      pushed: pushed.pushed,
      rejectedLocked: pushed.rejectedLocked,
      conflicts: pushed.conflicts,
      typeMismatches: pushed.typeMismatches,
      invalid: pushed.invalid,
      skippedDeletes: pushed.skippedDeletes,
    );
  }

  Future<SyncResult> _pull(
    _Snapshot snapshot, {
    Prefer? prefer,
    bool dryRun = false,
    Set<String>? keys,
  }) async {
    final state = _load(snapshot);
    final diffs = _only(
      classify(
        local: state.local,
        lock: state.lock,
        remote: snapshot.translations,
      ),
      keys,
    );
    final plan = planPull(diffs, prefer: prefer);

    final result = SyncResult(
      command: 'pull',
      dryRun: dryRun,
      counts: countStates(diffs),
      changes: diffs.where((e) => e.state != KeyState.unchanged).toList(),
      pulled: plan.updates,
      conflicts: [for (final diff in plan.conflicts) _conflictJson(diff)],
      unknownLocales: state.unknownLocales,
      localFilesChanged: plan.updates.isNotEmpty,
    );

    if (dryRun) {
      return result;
    }

    // Conflicts stop the run before anything is written, so nothing was pulled.
    if (plan.conflicts.isNotEmpty) {
      return result.copyWith(pulled: const [], localFilesChanged: false);
    }

    _writeLocales(state.files, plan.updates);

    for (final diff in [...plan.updates, ...plan.baseline]) {
      state.lock.acceptRemote(diff);
    }

    writeLock(_lockFile, state.lock);

    if (plan.updates.isEmpty || !config.generateKeys) {
      return result;
    }

    return result.copyWith(generatedKeys: regenerateKeys(snapshot.locales));
  }

  Future<SyncResult> _push(
    WriteKey writeKey,
    _Snapshot snapshot, {
    Prefer? prefer,
    bool dryRun = false,
    bool prune = false,
    Set<String>? keys,
  }) async {
    final preview = _planPush(
      snapshot,
      prefer: prefer,
      prune: prune,
      keys: keys,
    );
    final (:state, :diffs, :plan) = preview;

    if (plan.blocked) {
      return _blocked('push', snapshot, preview, dryRun: dryRun);
    }

    final base = SyncResult(
      command: 'push',
      dryRun: dryRun,
      counts: countStates(diffs),
      changes: diffs.where((e) => e.state != KeyState.unchanged).toList(),
      skippedDeletes: plan.skippedDeletes,
      unknownLocales: state.unknownLocales,
    );

    final pushed = <Map<String, dynamic>>[];
    final rejectedLocked = <Map<String, dynamic>>[];

    for (final chunk in plan.chunks) {
      final response = await _post(
        writeKey,
        chunk,
        dryRun: dryRun,
        appliedSoFar: pushed.length,
      );

      if (response['error'] == 'conflict') {
        return base.copyWith(
          pushed: pushed,
          rejectedLocked: rejectedLocked,
          conflicts: List<Map<String, dynamic>>.from(
            response['conflicts'] as List,
          ),
        );
      }

      final applied = List<Map<String, dynamic>>.from(
        response['applied'] as List? ?? [],
      );
      pushed.addAll(applied);
      rejectedLocked.addAll(
        List<Map<String, dynamic>>.from(
          response['rejected_locked'] as List? ?? [],
        ),
      );

      if (!dryRun) {
        final sent = {
          for (final change in chunk)
            '${change.locale}\u0000${change.key}': change,
        };

        for (final item in [
          ...applied,
          ...List<Map<String, dynamic>>.from(
            response['unchanged'] as List? ?? [],
          ),
        ]) {
          final change = sent['${item['locale']}\u0000${item['key']}'];
          if (change == null) continue;

          final ts = item['ts'];
          state.lock.set(
            change.locale,
            change.key,
            change.delete || ts is! num
                ? null
                : LockEntry(valueHash(change.value), ts.toInt()),
          );
        }

        writeLock(_lockFile, state.lock);
      }
    }

    return base.copyWith(pushed: pushed, rejectedLocked: rejectedLocked);
  }

  /// Result for a push plan that stops before any request.
  SyncResult _blocked(
    String command,
    _Snapshot snapshot,
    ({_State state, List<KeyDiff> diffs, PushPlan plan}) preview, {
    bool dryRun = false,
  }) {
    final (:state, :diffs, :plan) = preview;

    return SyncResult(
      command: command,
      dryRun: dryRun,
      counts: countStates(diffs),
      changes: diffs.where((e) => e.state != KeyState.unchanged).toList(),
      conflicts: [for (final diff in plan.conflicts) _conflictJson(diff)],
      typeMismatches: [
        for (final diff in plan.typeMismatches)
          {
            'locale': diff.locale,
            'key': diff.key,
            'local_value': diff.local,
            'remote_type': snapshot.keyTypes[diff.key],
          },
      ],
      invalid: [
        for (final (:diff, :reason) in plan.invalid)
          {'locale': diff.locale, 'key': diff.key, 'reason': reason},
      ],
      skippedDeletes: plan.skippedDeletes,
      unknownLocales: state.unknownLocales,
    );
  }

  /// Locale → key → value of every local locale file.
  LocalFiles readLocalFiles() => {
    for (final locale in localLocales())
      locale: readLocaleFile(localeFile(locale)).data,
  };

  /// Writes [plan] to the local locale files, keeping order and indent.
  void applyLocalChanges(LocalChangePlan plan) {
    for (final locale in plan.locales) {
      final file = readLocaleFile(localeFile(locale));

      writeLocaleFile(
        localeFile(locale),
        LocaleFile(
          applyLocaleChanges(
            file.data,
            plan.sets[locale] ?? const {},
            plan.removes.where(file.data.containsKey).toSet(),
          ),
          indent: file.indent,
          trailingNewline: file.trailingNewline,
        ),
      );
    }
  }

  /// Regenerates [keysOutputPath] from the locale files. Returns its path.
  String regenerateKeys(List<String> locales) {
    final decoded = {
      for (final locale in locales)
        locale: readLocaleFile(localeFile(locale)).data,
    };
    final setup = File('$_root/$setupJsonPath');
    final setupJson =
        setup.existsSync() ? jsonDecode(setup.readAsStringSync()) as Map : {};
    final defaultLocale =
        setupJson.isEmpty ? locales.first : resolveDefaultLocale(setupJson);
    final output = File('$_root/$keysOutputPath');

    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      generateLocalinoKeys(
        parseLocalinoKeys(decoded, defaultLocale: defaultLocale),
      ),
    );

    return keysOutputPath;
  }

  WriteKey _writeKey() {
    final key = readWriteKey(
      config.space,
      config.project,
      env: env,
      credentialsPath: credentialsPath,
    );

    if (key == null || !WriteKey.isValid(key.value)) {
      throw SyncException(
        SyncExit.auth,
        'No valid write key for ${config.space}/${config.project}. '
        'Run `dart run localino_builder login` (key on stdin) or set $writeKeyEnv.',
      );
    }

    return key;
  }

  _State _load(_Snapshot? snapshot) {
    final onDisk = localLocales();

    // `cs_cz` vs `cs_CZ.json`: one file on case-insensitive file systems, two locales for
    // apps and Linux. Stop before anything is merged into the wrong one.
    for (final remote in snapshot?.locales ?? const <String>[]) {
      for (final local in onDisk) {
        if (local != remote && local.toLowerCase() == remote.toLowerCase()) {
          throw SyncException(
            SyncExit.error,
            'Localino has the locale `$remote`, the local file is `$local`: the same '
            'locale in different letter case, which apps and case-sensitive file systems '
            'treat as two. Make them match (in the Localino console: remove the locale and '
            'add it again with the same case as the file), then re-run. Nothing was changed.',
          );
        }
      }
    }
    final locales = snapshot?.locales ?? onDisk;
    final indent =
        onDisk.isEmpty ? '  ' : readLocaleFile(localeFile(onDisk.first)).indent;
    final files = {
      for (final locale in locales)
        locale: readLocaleFile(localeFile(locale), fallbackIndent: indent),
    };

    return (
      files: files,
      local: {
        for (final entry in files.entries)
          entry.key: {
            for (final value in entry.value.data.entries)
              if (value.value != null) value.key: value.value,
          },
      },
      lock: readLock(_lockFile),
      unknownLocales: [
        for (final locale in onDisk)
          if (!locales.contains(locale)) locale,
      ],
    );
  }

  List<KeyDiff> _only(List<KeyDiff> diffs, Set<String>? keys) =>
      keys == null ? diffs : diffs.where((e) => keys.contains(e.key)).toList();

  void _writeLocales(Map<String, LocaleFile> files, List<KeyDiff> updates) {
    for (final locale in updates.map((e) => e.locale).toSet()) {
      final file = files[locale]!;
      final sets = <String, dynamic>{};
      final removes = <String>{};

      for (final diff in updates.where((e) => e.locale == locale)) {
        if (diff.remote == null) {
          removes.add(diff.key);
        } else {
          sets[diff.key] = diff.remote!.value;
        }
      }

      writeLocaleFile(
        localeFile(locale),
        LocaleFile(
          applyLocaleChanges(file.data, sets, removes),
          indent: file.indent,
          trailingNewline: file.trailingNewline,
        ),
      );
    }
  }

  /// Local state, diffs and the push plan against [snapshot].
  ({_State state, List<KeyDiff> diffs, PushPlan plan}) _planPush(
    _Snapshot snapshot, {
    Prefer? prefer,
    bool prune = false,
    Set<String>? keys,
  }) {
    final state = _load(snapshot);
    final diffs = _only(
      classify(
        local: state.local,
        lock: state.lock,
        remote: snapshot.translations,
      ),
      keys,
    );

    return (
      state: state,
      diffs: diffs,
      plan: planPush(
        diffs,
        prefer: prefer,
        prune: prune,
        remoteTypes: snapshot.keyTypes,
      ),
    );
  }

  Map<String, dynamic> _conflictJson(KeyDiff diff) => {
    'locale': diff.locale,
    'key': diff.key,
    'local_value': diff.local,
    'remote_value': diff.remote?.value,
    'remote_ts': diff.remote?.ts,
  };

  Uri _url(String route) {
    final base = apiUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/${config.space}/${config.project}/$route');
  }

  /// Local locale files Localino does not have.
  List<String> _missingLocales(_Snapshot snapshot) => [
    for (final locale in localLocales())
      if (!snapshot.locales.contains(locale)) locale,
  ];

  /// [snapshot] as it is once [locales] exist in Localino, still empty.
  _Snapshot _withLocales(_Snapshot snapshot, List<String> locales) =>
      locales.isEmpty
          ? snapshot
          : _Snapshot(
            [...snapshot.locales, ...locales],
            snapshot.keyTypes,
            {
              ...snapshot.translations,
              for (final locale in locales) locale: {},
            },
          );

  /// Creates [locales] in Localino (a dry run only checks them). Returns those the API
  /// added (or would add).
  Future<List<String>> _addLocales(
    WriteKey key,
    List<String> locales, {
    required bool dryRun,
  }) async {
    final response = await _send(
      () => client.post(
        _url('locales'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${key.value}',
        },
        body: jsonEncode({
          'dry_run': dryRun,
          'locales': [
            for (final locale in locales) {'locale': locale},
          ],
        }),
      ),
    );

    final body = _decode(response);

    switch (response.statusCode) {
      case 200:
        return [for (final locale in body['added'] as List? ?? []) '$locale'];
      case 401:
        throw SyncException(
          SyncExit.auth,
          'Write key rejected (unauthorized) for ${key.keyId}.',
        );
      case 409:
        throw const SyncException(
          SyncExit.network,
          'The project locales changed at the same time (contention) — re-run.',
        );
      case 422:
        final details = List<Map>.from(body['details'] as List? ?? []);
        throw SyncException(
          SyncExit.error,
          'Locales rejected: ${details.map((e) => [e['locale'], e['reason']].whereType<Object>().join(' ')).join('; ')} '
          '(file names must be `ll` or `ll_CC`, e.g. en_US).',
        );
      default:
        throw _statusError(response);
    }
  }

  Future<_Snapshot> _snapshot() async {
    final response = await _send(
      () => client.get(
        _url('snapshot'),
        headers: {'Accept': 'application/json', 'access': config.access},
      ),
    );

    if (response.statusCode == 401) {
      throw const SyncException(
        SyncExit.auth,
        'Read access denied — check `access` in setup.json.',
      );
    }

    if (response.statusCode != 200) {
      throw _statusError(response);
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    final locales = [for (final locale in json['locales'] as List) '$locale'];
    final translations = json['translations'] as Map? ?? {};

    return _Snapshot(
      locales,
      {
        for (final entry in (json['keys'] as Map? ?? {}).entries)
          '${entry.key}': '${(entry.value as Map?)?['type'] ?? 'text'}',
      },
      {
        for (final locale in locales)
          locale: {
            for (final entry in (translations[locale] as Map? ?? {}).entries)
              '${entry.key}': RemoteEntry(
                entry.value['value'],
                (entry.value['ts'] as num?)?.toInt() ?? 0,
              ),
          },
      },
    );
  }

  /// POSTs one chunk. Returns the 200 body, or the 409 conflict body.
  Future<Map<String, dynamic>> _post(
    WriteKey key,
    List<PushChange> chunk, {
    required bool dryRun,
    required int appliedSoFar,
  }) async {
    final response = await _send(
      () => client.post(
        _url('push'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${key.value}',
        },
        body: jsonEncode({
          'dry_run': dryRun,
          'changes': [for (final change in chunk) change.toJson()],
        }),
      ),
    );

    final body = _decode(response);
    final partial =
        appliedSoFar > 0
            ? ' $appliedSoFar changes were applied before this; re-run to continue.'
            : '';

    switch (response.statusCode) {
      case 200:
        return body;
      case 401:
        throw SyncException(
          SyncExit.auth,
          'Write key rejected (unauthorized) for ${key.keyId}.$partial',
        );
      case 409 when body['error'] == 'conflict':
        return body;
      case 409:
        throw SyncException(
          SyncExit.network,
          'Concurrent push (contention) — re-run.$partial',
        );
      case 413:
        throw SyncException(
          SyncExit.error,
          'Push too large (${body['locale'] ?? 'request'}).$partial',
        );
      case 422:
        final details = List<Map>.from(body['details'] as List? ?? []);
        final mismatch = details.any((e) => e['reason'] == 'type_mismatch');
        throw SyncException(
          mismatch ? SyncExit.conflict : SyncExit.error,
          'Push rejected: ${details.map((e) => [e['locale'], e['key'], e['reason']].whereType<Object>().join(' ')).join('; ')}.$partial',
        );
      default:
        throw _statusError(response, partial);
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json is Map<String, dynamic> ? json : {};
    } on FormatException {
      return {};
    }
  }

  SyncException _statusError(http.Response response, [String suffix = '']) =>
      SyncException(
        response.statusCode >= 500 ? SyncExit.network : SyncExit.error,
        'Localino responded ${response.statusCode}.$suffix',
      );

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw SyncException(
        SyncExit.network,
        'Localino did not respond within ${timeout.inSeconds}s.',
      );
    } on SocketException catch (e) {
      throw SyncException(
        SyncExit.network,
        'Cannot reach Localino: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw SyncException(
        SyncExit.network,
        'Cannot reach Localino: ${e.message}',
      );
    }
  }
}
