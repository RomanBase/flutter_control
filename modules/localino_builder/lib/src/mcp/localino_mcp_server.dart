import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../sync/io.dart';
import '../sync/merge.dart';
import '../sync/sync_engine.dart';

const _codegenHint =
    'Locale files changed — run the project localization codegen '
    '(e.g. `cd ci && dart run bin/localino.dart`), then preview with localino_push.';

const _askUser =
    'Nothing was written for these keys. Show the conflicts to the user and ask which '
    'side wins, then call again with `prefer` and `keys`.';

const _typeMismatch =
    'Nothing was pushed: Localino stores these keys with another value type (e.g. text '
    'vs a plural map) and push never changes a type. Tell the user; the key has to be '
    'changed or deleted in the Localino console first.';

final _keyPattern = RegExp(r'^[A-Za-z0-9_.\-]{1,200}$');

/// Anything shaped like a write key is masked in every tool output.
final _secretPattern = RegExp(r'lk_w_[0-9A-Za-z_]*');

class _ToolError implements Exception {
  final String message;
  final String? nextStep;

  const _ToolError(this.message, [this.nextStep]);
}

/// Local stdio MCP server: lets a coding agent search and set translation keys in the
/// project's locale files and sync them with Localino through [SyncEngine].
///
/// The write key is read inside the process (credentials file or env), never from tool
/// input, and never appears in tool output.
base class LocalinoMcpServer extends MCPServer with ToolsSupport {
  /// Project root holding the locale files and `.localino/lock.json`.
  final String root;
  final Map<String, String> env;
  final http.Client client;

  LocalinoMcpServer(
    super.channel, {
    required this.root,
    required this.env,
    required this.client,
  }) : super.fromStreamChannel(
         implementation: Implementation(name: 'localino', version: '1.2.0'),
         instructions:
             'Translations live in the project locale files. Use localino_search_keys '
             'before adding a key, localino_set_keys to edit locally, then '
             'localino_push (dry run) and show the plan to the user before applying.',
       ) {
    registerTool(statusTool, (request) => _guard(request, _status));
    registerTool(searchKeysTool, (request) => _guard(request, _searchKeys));
    registerTool(setKeysTool, (request) => _guard(request, _setKeys));
    registerTool(pullTool, (request) => _guard(request, _pull));
    registerTool(pushTool, (request) => _guard(request, _push));
  }

  static final _prefer = EnumSchema.untitledSingleSelect(
    values: ['local', 'remote'],
    description:
        'Resolve conflicts with this side. Only after the user chose it; '
        'combine with `keys` to limit it to the conflicts they decided.',
  );

  static final _keyFilter = Schema.list(
    items: Schema.string(),
    description: 'Only these translation keys (default: all).',
  );

  static final statusTool = Tool(
    name: 'localino_status',
    description:
        'Compares local locale files, .localino/lock.json and Localino. Returns counts '
        'per state (localChanged, remoteChanged, converged, conflict) and the changed '
        'keys. Offline it compares local files with the lock only.',
    annotations: ToolAnnotations(readOnlyHint: true, openWorldHint: true),
    inputSchema: Schema.object(
      properties: {
        'limit': Schema.int(
          description: 'Max changed keys listed (default 50).',
          minimum: 1,
          maximum: 500,
        ),
      },
    ),
  );

  static final searchKeysTool = Tool(
    name: 'localino_search_keys',
    description:
        'Searches the local locale files. Use before adding a key: matches on key '
        'names and values (case-insensitive substring), exact `keys`, or keys missing '
        'or empty in `missing_in`. Filters combine. Results flag keys with an identical '
        'value (`same_value_as`, `exact_value_match`) so an existing key can be reused.',
    annotations: ToolAnnotations(readOnlyHint: true, openWorldHint: false),
    inputSchema: Schema.object(
      properties: {
        'query': Schema.string(
          description: 'Substring of a key name or value.',
        ),
        'keys': Schema.list(
          items: Schema.string(),
          maxItems: 50,
          description: 'Exact translation keys to look up.',
        ),
        'missing_in': Schema.string(
          description: 'Locale (e.g. cs_CZ): only keys missing or empty there.',
        ),
        'limit': Schema.int(
          description: 'Max results (default 20).',
          minimum: 1,
          maximum: 200,
        ),
      },
    ),
  );

  static final setKeysTool = Tool(
    name: 'localino_set_keys',
    description:
        'Adds, updates or removes translation keys in the local locale files only '
        '(git-reversible; nothing is sent to Localino). Existing key order and indent '
        'are kept; new keys are appended sorted. Values may be strings, lists or maps '
        '(plurals). Unknown locales are rejected. Returns the diff and a codegen hint; '
        'regenerates lib/generated/localino_keys.dart when generate_keys is enabled.',
    annotations: ToolAnnotations(
      readOnlyHint: false,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: false,
    ),
    inputSchema: Schema.object(
      properties: {
        'keys': Schema.list(
          description: 'Keys to add or update.',
          items: Schema.object(
            properties: {
              'key': Schema.string(
                description: 'Translation key: A-Z a-z 0-9 _ . - (max 200).',
              ),
              'values': Schema.object(
                description:
                    'Locale → value, e.g. {"cs_CZ": "Zaplaceno"}. Locales left out '
                    'are not touched.',
                minProperties: 1,
              ),
            },
            required: ['key', 'values'],
          ),
        ),
        'remove': Schema.list(
          items: Schema.string(),
          description: 'Keys to remove from every local locale file.',
        ),
      },
    ),
  );

  static final pullTool = Tool(
    name: 'localino_pull',
    description:
        'Applies remote Localino changes to the local locale files and lock. Never '
        'drops local-only keys or local edits. Conflicts are listed and left untouched '
        'unless `prefer` is given.',
    annotations: ToolAnnotations(
      readOnlyHint: false,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: true,
    ),
    inputSchema: Schema.object(
      properties: {
        'dry_run': Schema.bool(
          description: 'Only report what would change (default false).',
        ),
        'prefer': _prefer,
        'keys': _keyFilter,
      },
    ),
  );

  static final pushTool = Tool(
    name: 'localino_push',
    description:
        'Sends local changes to Localino. Defaults to a dry run that returns the plan. '
        'Show the plan to the user and get their confirmation before calling again with '
        '`dry_run: false`. Ask the user before using `prefer`. Never deletes remote '
        'keys (remote deletes are CLI-only: `localino_builder push --prune`).',
    annotations: ToolAnnotations(
      readOnlyHint: false,
      destructiveHint: true,
      idempotentHint: false,
      openWorldHint: true,
    ),
    inputSchema: Schema.object(
      properties: {
        'dry_run': Schema.bool(
          description: 'Return the plan without writing (default true).',
        ),
        'prefer': _prefer,
        'keys': _keyFilter,
      },
    ),
  );

  Future<CallToolResult> _guard(
    CallToolRequest request,
    FutureOr<Map<String, dynamic>> Function(
      SyncEngine engine,
      Map<String, Object?> args,
    )
    tool,
  ) async {
    try {
      return _result(await tool(_engine(), request.arguments ?? const {}));
    } on SyncException catch (e) {
      return _error(e.message, _nextStep(e.exitCode));
    } on ConfigException catch (e) {
      return _error(e.message, 'Fix the Localino config, then retry.');
    } on _ToolError catch (e) {
      return _error(e.message, e.nextStep);
    } on FormatException catch (e) {
      return _error('Invalid JSON: ${e.message}', 'Fix the file, then retry.');
    } catch (e) {
      return _error('$e', null);
    }
  }

  SyncEngine _engine() {
    final config = loadConfig(root: root);

    if (config == null) {
      throw _ToolError(
        'Localino config not found under $root (build.yaml options or $setupJsonPath).',
        'Start the server from the project root, or pass --root.',
      );
    }

    return SyncEngine(
      config: config,
      client: client,
      apiUrl: resolveApiUrl(env),
      env: env,
      credentialsPath: defaultCredentialsPath(env),
    );
  }

  Future<Map<String, dynamic>> _status(
    SyncEngine engine,
    Map<String, Object?> args,
  ) async {
    final result = await engine.status();
    final counts = result.counts;
    final steps = [
      if (!result.remoteKnown)
        'Localino unreachable — showing local changes against the lock only.',
      if ((counts[KeyState.conflict] ?? 0) > 0) _askUser,
      if ((counts[KeyState.remoteChanged] ?? 0) > 0)
        'Remote changes: call localino_pull.',
      if ((counts[KeyState.localChanged] ?? 0) > 0)
        'Local changes: preview with localino_push.',
      if ((counts[KeyState.converged] ?? 0) > 0)
        'Converged keys (same value on both sides): localino_pull records them in the lock.',
    ];

    return {
      ..._summary(result, _limit(args, 50)),
      if (steps.isNotEmpty) 'next_step': steps.join(' '),
    };
  }

  Map<String, dynamic> _searchKeys(
    SyncEngine engine,
    Map<String, Object?> args,
  ) {
    final locales = engine.localLocales();
    final files = {
      for (final locale in locales)
        locale: readLocaleFile(engine.localeFile(locale)).data,
    };
    final missingIn = args['missing_in'] as String?;

    if (missingIn != null && !locales.contains(missingIn)) {
      throw _ToolError(
        'Unknown locale `$missingIn`. Local locales: ${locales.join(', ')}.',
      );
    }

    final query = (args['query'] as String?)?.trim().toLowerCase();
    final exact = (args['keys'] as List?)?.cast<String>().toSet();
    final limit = _limit(args, 20);
    final allKeys = {for (final data in files.values) ...data.keys};

    final index = <String, Set<String>>{};
    for (final locale in locales) {
      for (final entry in files[locale]!.entries) {
        if (_isEmpty(entry.value)) continue;
        (index['$locale\u0000${canonicalJson(entry.value)}'] ??= {}).add(
          entry.key,
        );
      }
    }

    final matches = <({String key, bool exactValue})>[];

    for (final key in allKeys.toList()..sort()) {
      if (exact != null && !exact.contains(key)) continue;
      if (missingIn != null && !_isEmpty(files[missingIn]![key])) continue;

      var exactValue = false;

      if (query != null && query.isNotEmpty) {
        final values = [
          for (final data in files.values)
            if (data[key] != null) data[key],
        ];
        final valueHit = values.any(
          (value) => _text(value).toLowerCase().contains(query),
        );
        exactValue = values.any(
          (value) => value is String && value.trim().toLowerCase() == query,
        );

        if (!key.toLowerCase().contains(query) && !valueHit) continue;
      }

      matches.add((key: key, exactValue: exactValue));
    }

    matches.sort((a, b) {
      if (a.exactValue != b.exactValue) return a.exactValue ? -1 : 1;
      return a.key.compareTo(b.key);
    });

    final shown = [
      for (final match in matches.take(limit))
        {
          'key': match.key,
          'values': {
            for (final locale in locales)
              if (files[locale]!.containsKey(match.key))
                locale: files[locale]![match.key],
          },
          if (match.exactValue) 'exact_value_match': true,
          if (_sameValue(match.key, locales, files, index) case final same
              when same.isNotEmpty)
            'same_value_as': same,
        },
    ];

    return {
      'locales': locales,
      'total': matches.length,
      'matches': shown,
      if (matches.length > limit) 'truncated': true,
      if (exact != null)
        'not_found':
            exact.where((key) => !allKeys.contains(key)).toList()..sort(),
      if (matches.any((e) => e.exactValue))
        'next_step':
            'A key with this exact value exists — reuse it instead of adding a duplicate.',
    };
  }

  Map<String, dynamic> _setKeys(SyncEngine engine, Map<String, Object?> args) {
    final locales = engine.localLocales();

    if (locales.isEmpty) {
      throw _ToolError(
        'No locale files match `${engine.config.asset}` under $root.',
      );
    }

    final entries = (args['keys'] as List? ?? const []).cast<Map>();
    final removes =
        (args['remove'] as List? ?? const []).cast<String>().toSet();

    if (entries.isEmpty && removes.isEmpty) {
      throw const _ToolError('Nothing to change: pass `keys` or `remove`.');
    }

    final sets = <String, Map<String, dynamic>>{};
    final errors = <String>[];

    for (final entry in entries) {
      final key = entry['key'] as String;
      final values = entry['values'] as Map;

      if (!_keyPattern.hasMatch(key) ||
          (key.startsWith('__') && key.endsWith('__'))) {
        errors.add('`$key`: invalid key (A-Z a-z 0-9 _ . -, max 200)');
      }

      if (removes.contains(key)) {
        errors.add('`$key`: both set and removed');
      }

      for (final value in values.entries) {
        final locale = '${value.key}';

        if (!locales.contains(locale)) {
          errors.add('`$key`: unknown locale `$locale`');
        } else if (value.value is! String &&
            value.value is! List &&
            value.value is! Map) {
          errors.add(
            '`$key` $locale: value must be a string, list or map (use `remove` to delete)',
          );
        } else {
          (sets[locale] ??= {})[key] = value.value;
        }
      }
    }

    if (errors.isNotEmpty) {
      throw _ToolError(
        '${errors.join('; ')}.',
        'Local locales: ${locales.join(', ')}. Nothing was written.',
      );
    }

    final diff = <Map<String, dynamic>>[];
    var changed = false;

    for (final locale in locales) {
      final file = readLocaleFile(engine.localeFile(locale));
      final localeSets = sets[locale] ?? const <String, dynamic>{};
      final localeRemoves = removes.where(file.data.containsKey).toSet();
      final before = diff.length;

      for (final entry in localeSets.entries) {
        final old = file.data[entry.key];

        if (!file.data.containsKey(entry.key)) {
          diff.add({
            'locale': locale,
            'key': entry.key,
            'change': 'added',
            'new': entry.value,
          });
        } else if (canonicalJson(old) != canonicalJson(entry.value)) {
          diff.add({
            'locale': locale,
            'key': entry.key,
            'change': 'updated',
            'old': old,
            'new': entry.value,
          });
        }
      }

      for (final key in localeRemoves) {
        diff.add({
          'locale': locale,
          'key': key,
          'change': 'removed',
          'old': file.data[key],
        });
      }

      if (diff.length == before) continue;

      changed = true;
      writeLocaleFile(
        engine.localeFile(locale),
        LocaleFile(
          applyLocaleChanges(file.data, localeSets, localeRemoves),
          indent: file.indent,
          trailingNewline: file.trailingNewline,
        ),
      );
    }

    final after = {
      for (final locale in locales)
        locale: readLocaleFile(engine.localeFile(locale)).data,
    };
    final incomplete = [
      for (final entry in entries)
        if ([
              for (final locale in locales)
                if (_isEmpty(after[locale]![entry['key']])) locale,
            ]
            case final missing when missing.isNotEmpty)
          {'key': entry['key'], 'missing_in': missing},
    ];

    return {
      'changed': changed,
      'diff': diff,
      if (incomplete.isNotEmpty) 'incomplete': incomplete,
      if (changed && engine.config.generateKeys)
        'generated_keys': engine.regenerateKeys(locales),
      if (changed) 'next_step': _codegenHint,
    };
  }

  Future<Map<String, dynamic>> _pull(
    SyncEngine engine,
    Map<String, Object?> args,
  ) async {
    final result = await engine.pull(
      prefer: parsePrefer(args['prefer'] as String?),
      dryRun: args['dry_run'] as bool? ?? false,
      keys: _keys(args),
    );

    return {
      ..._summary(result, 50),
      if (result.conflicts.isNotEmpty)
        'next_step': _askUser
      else if (result.localFilesChanged && !result.dryRun)
        'next_step': _codegenHint,
    };
  }

  Future<Map<String, dynamic>> _push(
    SyncEngine engine,
    Map<String, Object?> args,
  ) async {
    final result = await engine.push(
      prefer: parsePrefer(args['prefer'] as String?),
      dryRun: args['dry_run'] as bool? ?? true,
      keys: _keys(args),
    );
    final steps = [
      if (result.typeMismatches.isNotEmpty)
        _typeMismatch
      else if (result.conflicts.isNotEmpty)
        _askUser
      else if (result.dryRun && result.pushed.isNotEmpty)
        'Show this plan to the user and get their confirmation, then call '
            'localino_push with `dry_run: false`.'
      else if (result.pushed.isEmpty)
        'Nothing to push.',
      if (result.skippedDeletes.isNotEmpty)
        'Local deletes were not sent; remote deletes are CLI-only '
            '(`localino_builder push --prune`).',
    ];

    return {
      ..._summary(result, 50),
      if (steps.isNotEmpty) 'next_step': steps.join(' '),
    };
  }

  /// [SyncResult.toJson] with every list capped at [limit]; `truncated` holds the
  /// full lengths of capped lists.
  Map<String, dynamic> _summary(SyncResult result, int limit) {
    final json = result.toJson();
    final truncated = <String, int>{};

    for (final entry in json.entries.toList()) {
      if (entry.value is List && (entry.value as List).length > limit) {
        truncated[entry.key] = (entry.value as List).length;
        json[entry.key] = (entry.value as List).take(limit).toList();
      }
    }

    return {...json, if (truncated.isNotEmpty) 'truncated': truncated};
  }

  CallToolResult _result(Map<String, dynamic> data) {
    final text = _redact(jsonEncode(data));

    return CallToolResult(
      content: [TextContent(text: text)],
      structuredContent: jsonDecode(text) as Map<String, Object?>,
    );
  }

  CallToolResult _error(String message, String? nextStep) {
    final text = _redact(
      jsonEncode({
        'error': message,
        if (nextStep != null) 'next_step': nextStep,
      }),
    );

    return CallToolResult(
      content: [TextContent(text: text)],
      structuredContent: jsonDecode(text) as Map<String, Object?>,
      isError: true,
    );
  }
}

String? _nextStep(int exitCode) => switch (exitCode) {
  SyncExit.auth =>
    'Ask the user to fix credentials in their terminal: write key via '
        '`dart run localino_builder login` (key on stdin — never in chat), read token '
        'via `access` in setup.json.',
  SyncExit.network =>
    'Localino is unreachable or busy; local files are unchanged. Retry later.',
  SyncExit.conflict =>
    'A key changed shape (text, list or map) versus Localino. Ask the user how to resolve it.',
  _ => null,
};

String _redact(String text) => text.replaceAll(_secretPattern, 'lk_w_***');

int _limit(Map<String, Object?> args, int fallback) =>
    (args['limit'] as num?)?.toInt() ?? fallback;

Set<String>? _keys(Map<String, Object?> args) =>
    (args['keys'] as List?)?.cast<String>().toSet();

bool _isEmpty(Object? value) =>
    value == null ||
    (value is String && value.trim().isEmpty) ||
    (value is Map && value.isEmpty) ||
    (value is List && value.isEmpty);

String _text(Object? value) => value is String ? value : canonicalJson(value);

/// Other keys holding exactly this key's value in the same locale (max 10).
List<String> _sameValue(
  String key,
  List<String> locales,
  Map<String, Map<String, dynamic>> files,
  Map<String, Set<String>> index,
) {
  final same = <String>{};

  for (final locale in locales) {
    final value = files[locale]![key];
    if (_isEmpty(value)) continue;
    same.addAll(index['$locale\u0000${canonicalJson(value)}'] ?? const {});
  }

  return ((same..remove(key)).toList()..sort()).take(10).toList();
}
