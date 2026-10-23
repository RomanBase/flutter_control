import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../key_generator.dart';
import '../key_parser.dart';
import 'io.dart';
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
  final List<KeyDiff> skippedDeletes;

  /// Local locale files Localino does not have; skipped.
  final List<String> unknownLocales;

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
    this.skippedDeletes = const [],
    this.unknownLocales = const [],
    this.localFilesChanged = false,
    this.generatedKeys,
  });

  int get exitCode =>
      conflicts.isEmpty && typeMismatches.isEmpty
          ? SyncExit.ok
          : SyncExit.conflict;

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
    'skipped_deletes': [for (final diff in skippedDeletes) diff.toJson()],
    'unknown_locales': unknownLocales,
    'local_files_changed': localFilesChanged,
    if (generatedKeys != null) 'generated_keys': generatedKeys,
  };
}

class _Snapshot {
  final List<String> locales;

  /// key → `{type, locked}`.
  final Map<String, dynamic> keys;
  final Map<String, Map<String, RemoteEntry>> translations;

  const _Snapshot(this.locales, this.keys, this.translations);
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
  }) async {
    final snapshot = await _snapshot();
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

    if (dryRun || plan.conflicts.isNotEmpty) {
      return result;
    }

    _writeLocales(state.files, plan.updates);

    for (final diff in [...plan.updates, ...plan.baseline]) {
      state.lock.acceptRemote(diff);
    }

    writeLock(_lockFile, state.lock);

    if (plan.updates.isEmpty || !config.generateKeys) {
      return result;
    }

    return SyncResult(
      command: result.command,
      counts: result.counts,
      changes: result.changes,
      pulled: result.pulled,
      unknownLocales: result.unknownLocales,
      localFilesChanged: true,
      generatedKeys: regenerateKeys(snapshot.locales),
    );
  }

  Future<SyncResult> push({
    Prefer? prefer,
    bool dryRun = false,
    bool prune = false,
    Set<String>? keys,
  }) async {
    final writeKey = _writeKey();
    final (:snapshot, :state, :diffs, :plan) = await _planPush(
      prefer: prefer,
      prune: prune,
      keys: keys,
    );

    final base = SyncResult(
      command: 'push',
      dryRun: dryRun,
      counts: countStates(diffs),
      changes: diffs.where((e) => e.state != KeyState.unchanged).toList(),
      conflicts: [for (final diff in plan.conflicts) _conflictJson(diff)],
      typeMismatches: [
        for (final diff in plan.typeMismatches) _mismatchJson(diff, snapshot),
      ],
      skippedDeletes: plan.skippedDeletes,
      unknownLocales: state.unknownLocales,
    );

    if (plan.conflicts.isNotEmpty || plan.typeMismatches.isNotEmpty) {
      return base;
    }

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
        return SyncResult(
          command: base.command,
          dryRun: dryRun,
          counts: base.counts,
          changes: base.changes,
          pushed: pushed,
          rejectedLocked: rejectedLocked,
          conflicts: List<Map<String, dynamic>>.from(
            response['conflicts'] as List,
          ),
          skippedDeletes: base.skippedDeletes,
          unknownLocales: base.unknownLocales,
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

    return SyncResult(
      command: base.command,
      dryRun: dryRun,
      counts: base.counts,
      changes: base.changes,
      pushed: pushed,
      rejectedLocked: rejectedLocked,
      skippedDeletes: base.skippedDeletes,
      unknownLocales: base.unknownLocales,
    );
  }

  /// Pull, then push. A push failure after a successful pull keeps the pull applied;
  /// type mismatches are found before the pull, so they leave both sides untouched.
  Future<SyncResult> sync({Prefer? prefer, bool prune = false}) async {
    _writeKey();

    final preview = await _planPush(prefer: prefer, prune: prune);

    if (preview.plan.typeMismatches.isNotEmpty) {
      return SyncResult(
        command: 'sync',
        counts: countStates(preview.diffs),
        changes:
            preview.diffs.where((e) => e.state != KeyState.unchanged).toList(),
        typeMismatches: [
          for (final diff in preview.plan.typeMismatches)
            _mismatchJson(diff, preview.snapshot),
        ],
        unknownLocales: preview.state.unknownLocales,
      );
    }

    final pulled = await pull(prefer: prefer);

    if (pulled.conflicts.isNotEmpty) {
      return SyncResult(
        command: 'sync',
        counts: pulled.counts,
        changes: pulled.changes,
        conflicts: pulled.conflicts,
        unknownLocales: pulled.unknownLocales,
      );
    }

    final SyncResult pushed;

    try {
      pushed = await push(prefer: prefer, prune: prune);
    } on SyncException catch (e) {
      throw SyncException(
        e.exitCode,
        e.exitCode == SyncExit.network
            ? 'Pulled ${pulled.pulled.length} keys; push pending — re-run `sync`. ${e.message}'
            : 'Pulled ${pulled.pulled.length} keys; push failed. ${e.message}',
      );
    }

    return SyncResult(
      command: 'sync',
      counts: pushed.counts,
      changes: pushed.changes,
      pulled: pulled.pulled,
      pushed: pushed.pushed,
      rejectedLocked: pushed.rejectedLocked,
      conflicts: pushed.conflicts,
      skippedDeletes: pushed.skippedDeletes,
      unknownLocales: pushed.unknownLocales,
      localFilesChanged: pulled.localFilesChanged,
      generatedKeys: pulled.generatedKeys,
    );
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

  /// Snapshot, local state, diffs and the push plan for [push] (and the [sync] preview).
  Future<
    ({_Snapshot snapshot, _State state, List<KeyDiff> diffs, PushPlan plan})
  >
  _planPush({Prefer? prefer, bool prune = false, Set<String>? keys}) async {
    final snapshot = await _snapshot();
    final state = _load(snapshot);
    final diffs = _only(
      classify(
        local: state.local,
        lock: state.lock,
        remote: snapshot.translations,
      ),
      keys,
    );
    final plan = planPush(
      diffs,
      prefer: prefer,
      prune: prune,
      remoteKeys: snapshot.keys.keys.toSet(),
      remoteTypes: {
        for (final entry in snapshot.keys.entries)
          entry.key: '${(entry.value as Map?)?['type']}',
      },
    );

    return (snapshot: snapshot, state: state, diffs: diffs, plan: plan);
  }

  Map<String, dynamic> _mismatchJson(KeyDiff diff, _Snapshot snapshot) => {
    'locale': diff.locale,
    'key': diff.key,
    'local_value': diff.local,
    'remote_type': (snapshot.keys[diff.key] as Map?)?['type'],
  };

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
      Map<String, dynamic>.from(json['keys'] as Map? ?? {}),
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
