import 'dart:io';

import 'package:build/build.dart';
import 'package:http/http.dart' as http;
import 'package:localino_builder/build.dart';
import 'package:localino_builder/src/config.dart';
import 'package:localino_builder/src/sync/io.dart';
import 'package:localino_builder/src/sync/merge.dart';
import 'package:localino_builder/src/sync/sync_engine.dart';

const _commands = {'status', 'pull', 'push', 'sync', 'login'};
const _listLimit = 50;

const _usage = '''
Localino builder — download, or sync translations with Localino.

Usage:
  dart run localino_builder [-u <access> -sp <space:project>] [--generate-keys] [--report-unused]
      Legacy download: overwrites local locale files with Localino.

  dart run localino_builder <command> [options]
    status                         Compare local files, .localino/lock.json and Localino.
    pull   [--prefer local|remote] [--dry-run]
                                   Apply remote changes; never drops local-only keys.
    push   [--prefer local|remote] [--dry-run] [--prune]
                                   Send local changes (write key required). Deletes only with --prune.
    sync   [--prefer local|remote] Pull, then push.
    login                          Store the project write key read from stdin
                                   (~/.localino/credentials.json, mode 600).

Options:
  --root <dir>   Project root (default: nearest pubspec.yaml).
  -h, --help     Show this help.

Environment:
  LOCALINO_WRITE_KEY   Write key (overrides credentials file).
  LOCALINO_API_URL     API base (default https://api.localino.app/v1; https only, http for localhost).

Exit codes: 0 ok · 1 usage/other · 3 conflict · 4 auth · 5 network/contention (re-run).''';

void main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    print(_usage);
    return;
  }

  if (arguments.isNotEmpty && _commands.contains(arguments.first)) {
    try {
      exitCode = await _run(arguments.first, arguments.skip(1).toList());
    } on FormatException catch (e) {
      stderr.writeln('Invalid file content: ${e.message}');
      exitCode = SyncExit.error;
    } catch (e) {
      stderr.writeln('$e');
      exitCode = SyncExit.error;
    }
    return;
  }

  _legacy(arguments);
}

void _legacy(List<String> arguments) {
  print('Localino Run Binary');

  // Overwrites the locale files, so only an explicit args / build.yaml config runs it.
  final config = loadConfig(args: arguments, root: '.', setupFallback: false);

  if (config == null) {
    print('Localino Config Not Found');
    return;
  }

  build(BuilderOptions({...config.options}));
}

Future<int> _run(String command, List<String> args) async {
  final prefer = option(args, '--prefer');

  if (prefer != null && parsePrefer(prefer) == null) {
    stderr.writeln('--prefer must be `local` or `remote`.\n\n$_usage');
    return SyncExit.error;
  }

  final root =
      option(args, '--root') ?? findProjectRoot(Directory.current.path);
  final config = loadConfig(root: root);

  if (config == null) {
    stderr.writeln(
      'Localino config not found under $root (build.yaml options or $setupJsonPath).',
    );
    return SyncExit.error;
  }

  final env = Platform.environment;
  final credentialsPath = defaultCredentialsPath(env);

  if (command == 'login') {
    return _login(config, credentialsPath);
  }

  final client = http.Client();

  try {
    final engine = SyncEngine(
      config: config,
      client: client,
      apiUrl: resolveApiUrl(env),
      env: env,
      credentialsPath: credentialsPath,
    );
    final dryRun = args.contains('--dry-run');

    final result = switch (command) {
      'status' => await engine.status(),
      'pull' => await engine.pull(prefer: parsePrefer(prefer), dryRun: dryRun),
      'push' => await engine.push(
        prefer: parsePrefer(prefer),
        dryRun: dryRun,
        prune: args.contains('--prune'),
      ),
      _ => await engine.sync(prefer: parsePrefer(prefer)),
    };

    _report(result);
    return result.exitCode;
  } on ConfigException catch (e) {
    stderr.writeln(e.message);
    return SyncExit.error;
  } on SyncException catch (e) {
    stderr.writeln(e.message);
    return e.exitCode;
  } finally {
    client.close();
  }
}

int _login(LocalinoConfig config, String? credentialsPath) {
  if (credentialsPath == null) {
    stderr.writeln(
      'Cannot locate home directory for ~/.localino/credentials.json; set $writeKeyEnv instead.',
    );
    return SyncExit.error;
  }

  stderr.writeln(
    'Paste the write key for ${config.space}/${config.project}, then press Enter:',
  );

  final terminal = stdin.hasTerminal;
  if (terminal) stdin.echoMode = false;

  final String line;

  try {
    line = stdin.readLineSync()?.trim() ?? '';
  } finally {
    if (terminal) stdin.echoMode = true;
  }

  if (!WriteKey.isValid(line)) {
    stderr.writeln('Not a Localino write key (expected lk_w_…).');
    return SyncExit.auth;
  }

  final key = WriteKey(line);
  storeWriteKey(
    config.space,
    config.project,
    key,
    credentialsPath: credentialsPath,
  );
  print(
    'Stored $key for ${config.space}/${config.project} in $credentialsPath',
  );

  return SyncExit.ok;
}

void _report(SyncResult result) {
  final title = '${result.command}${result.dryRun ? ' (dry run)' : ''}';
  print('Localino $title');

  if (!result.remoteKnown) {
    print(
      '  Remote unreachable — showing local changes against .localino/lock.json only.',
    );
  }

  final counts = result.counts.entries
      .where((e) => e.value > 0)
      .map((e) => '${e.key.name}: ${e.value}');
  if (counts.isNotEmpty) print('  ${counts.join(', ')}');

  if (result.command == 'status') {
    _list(
      'Changes',
      result.changes.map(
        (e) => '${e.locale} ${e.key} — ${e.state.name}${_flags(e)}',
      ),
    );
  }

  _list(
    result.dryRun ? 'Would pull' : 'Pulled',
    result.pulled.map((e) => '${e.locale} ${e.key}${_flags(e)}'),
  );
  _list(
    result.dryRun ? 'Would push' : 'Pushed',
    result.pushed.map((e) => '${e['locale']} ${e['key']}'),
  );
  _list(
    'Rejected (locked in Localino)',
    result.rejectedLocked.map((e) => '${e['locale']} ${e['key']}'),
  );
  _list(
    'Local deletes not pushed (use --prune)',
    result.skippedDeletes.map((e) => '${e.locale} ${e.key}'),
  );
  _list('Locales unknown to Localino (skipped)', result.unknownLocales);
  _list('Conflicts', result.conflicts.map((e) => '${e['locale']} ${e['key']}'));

  if (result.conflicts.isNotEmpty) {
    print('  Nothing written. Resolve with --prefer local or --prefer remote.');
  }
  _list(
    'Not accepted by Localino',
    result.invalid.map((e) => '${e['locale']} ${e['key']} (${e['reason']})'),
  );

  if (result.invalid.isNotEmpty) {
    print(
      '  Nothing written. Fix these keys or values in the locale files '
      '(keys: A-Z a-z 0-9 _ . -; values: text, list or map, one shape per key), then re-run.',
    );
  }

  _list(
    'Type differs from Localino',
    result.typeMismatches.map(
      (e) => '${e['locale']} ${e['key']} (Localino: ${e['remote_type']})',
    ),
  );

  if (result.typeMismatches.isNotEmpty) {
    print(
      '  Nothing written. Localino never changes a key\'s type through push: '
      'change or delete these keys in the Localino console, then re-run.',
    );
  }

  if (result.generatedKeys != null) {
    print('  Regenerated ${result.generatedKeys}');
  }

  if (result.localFilesChanged && !result.dryRun) {
    print('  Locale files changed — run your project localization codegen.');
  }
}

String _flags(KeyDiff diff) =>
    diff.added ? ' (added)' : (diff.deleted ? ' (deleted)' : '');

void _list(String label, Iterable<String> items) {
  final list = items.toList();
  if (list.isEmpty) return;

  print('  $label (${list.length}):');
  for (final item in list.take(_listLimit)) {
    print('    $item');
  }
  if (list.length > _listLimit) print('    … ${list.length - _listLimit} more');
}
