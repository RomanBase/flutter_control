import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../sync/io.dart';
import '../sync/local_keys.dart';
import '../sync/merge.dart';
import '../sync/sync_engine.dart';
import '../version.dart';

const _codegenHint =
    'Locale files changed — run the project localization codegen '
    '(e.g. `cd ci && dart run bin/localino.dart`), then preview with localino_push.';

const _askUser =
    'Nothing was written for these keys. Show the conflicts to the user and ask which '
    'side wins, then call again with `prefer` and `keys`.';

const _invalid =
    'Nothing was pushed: some keys or values are not accepted by Localino (see `invalid`). '
    'Fix them in the locale files (localino_set_keys), then preview again.';

const _typeMismatch =
    'Nothing was pushed: Localino stores these keys with another value type (e.g. text '
    'vs a plural map) and push never changes a type. Tell the user; the key has to be '
    'changed or deleted in the Localino console first.';

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
         implementation: Implementation(
           name: 'localino',
           version: packageVersion,
         ),
         instructions:
             'Translations live in the project locale files. Use localino_search_keys '
             'before adding a key, localino_set_keys to edit locally, then '
             'localino_push (dry run) and show the plan to the user before applying.',
       ) {
    registerTool(statusTool, (request) => _guard(request, _status));
    registerTool(
      searchKeysTool,
      (request) => _guard(request, _searchKeys, remote: false),
    );
    registerTool(
      setKeysTool,
      (request) => _guard(request, _setKeys, remote: false),
    );
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
    tool, {
    bool remote = true,
  }) async {
    try {
      return _result(
        await tool(_engine(remote: remote), request.arguments ?? const {}),
      );
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

  /// Engine for one call. Local-only tools ([remote] false) never reach Localino, so a
  /// bad `LOCALINO_API_URL` does not block them.
  SyncEngine _engine({bool remote = true}) {
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
      apiUrl: remote ? resolveApiUrl(env) : Uri.parse(defaultApiUrl),
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
    final files = engine.readLocalFiles();
    final missingIn = args['missing_in'] as String?;

    if (missingIn != null && !files.containsKey(missingIn)) {
      throw _ToolError(
        'Unknown locale `$missingIn`. Local locales: ${files.keys.join(', ')}.',
      );
    }

    final result = searchKeys(
      files,
      query: args['query'] as String?,
      keys: (args['keys'] as List?)?.cast<String>().toSet(),
      missingIn: missingIn,
      limit: _limit(args, 20),
    );
    final matches = (result['matches'] as List).cast<Map>();

    return {
      ...result,
      if (matches.any((e) => e['exact_value_match'] == true))
        'next_step':
            'A key with this exact value exists — reuse it instead of adding a duplicate.',
    };
  }

  Map<String, dynamic> _setKeys(SyncEngine engine, Map<String, Object?> args) {
    final files = engine.readLocalFiles();

    if (files.isEmpty) {
      throw _ToolError(
        'No locale files match `${engine.config.asset}` under $root.',
      );
    }

    final entries = [
      for (final entry in (args['keys'] as List? ?? const []).cast<Map>())
        (
          key: entry['key'] as String,
          values: Map<String, dynamic>.from(entry['values'] as Map),
        ),
    ];
    final removes =
        (args['remove'] as List? ?? const []).cast<String>().toSet();

    if (entries.isEmpty && removes.isEmpty) {
      throw const _ToolError('Nothing to change: pass `keys` or `remove`.');
    }

    final plan = planSetKeys(files, entries, removes);

    if (plan.errors.isNotEmpty) {
      throw _ToolError(
        '${plan.errors.join('; ')}.',
        'Local locales: ${files.keys.join(', ')}. Nothing was written.',
      );
    }

    engine.applyLocalChanges(plan);

    return {
      'changed': plan.changed,
      'diff': plan.diff,
      if (plan.incomplete.isNotEmpty) 'incomplete': plan.incomplete,
      if (plan.changed && engine.config.generateKeys)
        'generated_keys': engine.regenerateKeys(files.keys.toList()),
      if (plan.changed) 'next_step': _codegenHint,
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
      if (result.invalid.isNotEmpty)
        _invalid
      else if (result.typeMismatches.isNotEmpty)
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

  /// [data] as JSON text and structured content, with write keys masked.
  CallToolResult _result(Map<String, dynamic> data, {bool isError = false}) {
    final text = _redact(jsonEncode(data));

    return CallToolResult(
      content: [TextContent(text: text)],
      structuredContent: jsonDecode(text) as Map<String, Object?>,
      isError: isError ? true : null,
    );
  }

  CallToolResult _error(String message, String? nextStep) => _result({
    'error': message,
    if (nextStep != null) 'next_step': nextStep,
  }, isError: true);
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
