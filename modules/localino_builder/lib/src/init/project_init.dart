import 'dart:convert';
import 'dart:io';

import '../config.dart';
import '../sync/io.dart';
import '../version.dart';

const mcpJsonPath = '.mcp.json';
const _serverName = 'localino';
const _blockBegin = '<!-- localino:begin';
const _blockEnd = '<!-- localino:end -->';

/// Agent rule files `init` writes into, relative to the workspace root; the first that
/// exists wins, else the last is created.
const ruleCandidates = ['rules/localization.md', 'AGENTS.md', 'CLAUDE.md'];

final _codegenLine = RegExp(
  r'\*\*Codegen\*\* after any change to the locale files: `([^`]+)`',
);
final _handWrittenSync = RegExp(r'localino_builder (pull|push|sync)\b');

/// A file `init` creates or changes, relative to [InitPlan.workspaceRoot].
class InitFile {
  final String path;

  /// Content before, or null for a new file.
  final String? before;
  final String after;

  const InitFile(this.path, this.before, this.after);

  bool get changed => before != after;
}

/// What `localino_builder init` writes, computed without touching disk.
class InitPlan {
  final LocalinoConfig config;

  /// Nearest directory at or above the project holding `.git`; `.mcp.json` and the agent
  /// rules live here, where coding agents start.
  final String workspaceRoot;

  /// Project directory relative to [workspaceRoot]; empty when they are the same.
  final String projectDir;

  final InitFile mcpJson;
  final InitFile rules;

  /// The `localino` server entry; null when `.mcp.json` already had one, kept as is.
  final Map<String, Object?>? server;

  /// Shell prefix for the CLI, e.g. `fvm dart run localino_builder`.
  final String run;
  final List<String> warnings;

  const InitPlan({
    required this.config,
    required this.workspaceRoot,
    required this.projectDir,
    required this.mcpJson,
    required this.rules,
    required this.server,
    required this.run,
    required this.warnings,
  });

  List<InitFile> get files => [mcpJson, rules];

  /// Writes the changed files.
  void apply() {
    for (final file in files.where((e) => e.changed)) {
      File('$workspaceRoot/${file.path}')
        ..createSync(recursive: true)
        ..writeAsStringSync(file.after);
    }
  }
}

/// Plans `init` for [config]: registers the MCP server in `.mcp.json` and writes the
/// managed Localino block into the agent rules ([rules] overrides the target). [codegen]
/// is the project's localization codegen command; without it, the one from a previous
/// block is kept.
InitPlan planInit(LocalinoConfig config, {String? codegen, String? rules}) {
  final command = codegen?.trim();

  if (command != null && command.contains('`')) {
    throw const ConfigException('--codegen must not contain backticks.');
  }

  final projectRoot = Directory(config.root).resolveSymbolicLinksSync();
  final workspaceRoot = findWorkspaceRoot(projectRoot);
  final projectDir =
      projectRoot == workspaceRoot
          ? ''
          : projectRoot.substring(workspaceRoot.length + 1);
  final fvm = sharedFvmConfig(projectRoot, workspaceRoot);
  final run = '${fvm ? 'fvm ' : ''}dart run localino_builder';
  final warnings = <String>[];

  final mcpBefore = _read('$workspaceRoot/$mcpJsonPath');
  final launch = mcpServer(projectDir: projectDir, fvm: fvm);
  final mcpAfter = mergeMcpJson(mcpBefore, launch);
  final existing = mcpAfter == mcpBefore && mcpBefore != null;

  if (existing && !_sameServer(mcpBefore, launch)) {
    warnings.add(
      '$mcpJsonPath already registers `$_serverName` differently — kept it. init would '
      'write: ${_inline(launch)}',
    );
  }

  final rulesPath =
      rules ??
      ruleCandidates.firstWhere(
        (path) => File('$workspaceRoot/$path').existsSync(),
        orElse: () => ruleCandidates.last,
      );
  final rulesBefore = _read('$workspaceRoot/$rulesPath');
  final block = rulesBlock(
    config,
    run: run,
    projectDir: projectDir,
    codegen:
        (command?.isEmpty ?? true) ? previousCodegen(rulesBefore) : command,
  );
  final rulesAfter = applyRulesBlock(rulesBefore, block);

  if (_handWrittenSync.hasMatch(_outsideBlock(rulesBefore ?? ''))) {
    warnings.add(
      '$rulesPath also describes localino_builder sync outside the managed block — '
      'remove that section so agents follow one version.',
    );
  }

  if (rulesPath.contains('/') &&
      !['AGENTS.md', 'CLAUDE.md'].any(
        (path) => _read('$workspaceRoot/$path')?.contains(rulesPath) ?? false,
      )) {
    warnings.add(
      'Neither AGENTS.md nor CLAUDE.md mentions $rulesPath — point your coding agent at it.',
    );
  }

  return InitPlan(
    config: config,
    workspaceRoot: workspaceRoot,
    projectDir: projectDir,
    mcpJson: InitFile(mcpJsonPath, mcpBefore, mcpAfter),
    rules: InitFile(rulesPath, rulesBefore, rulesAfter),
    server: existing ? null : launch,
    run: run,
    warnings: warnings,
  );
}

/// Nearest directory at or above [start] holding `.git` (a directory, or a file in a
/// worktree), else [start].
String findWorkspaceRoot(String start) {
  var dir = Directory(start);

  while (true) {
    if (FileSystemEntity.typeSync('${dir.path}/.git') !=
        FileSystemEntityType.notFound) {
      return dir.path;
    }

    final parent = dir.parent;

    if (parent.path == dir.path) {
      return start;
    }

    dir = parent;
  }
}

/// Whether the project shares an fvm config (`.fvmrc` or `.fvm/fvm_config.json` in
/// [projectRoot] or [workspaceRoot]). `.mcp.json` and the rules are committed, so a
/// config git does not track (a personal fvm setup) does not count; outside git an
/// existing file does.
bool sharedFvmConfig(String projectRoot, String workspaceRoot) {
  for (final dir in {projectRoot, workspaceRoot}) {
    for (final name in ['.fvmrc', '.fvm/fvm_config.json']) {
      if (!File('$dir/$name').existsSync()) continue;

      final ProcessResult tracked;

      try {
        tracked = Process.runSync('git', [
          '-C',
          dir,
          'ls-files',
          '--error-unmatch',
          name,
        ]);
      } on ProcessException {
        return true;
      }

      // 0 tracked, 1 untracked; anything else means no usable git here.
      if (tracked.exitCode != 1) return true;
    }
  }

  return false;
}

/// The `.mcp.json` entry that starts the server from the workspace root. A nested
/// project ([projectDir] not empty) runs through `dart pub -C`, which needs no shell.
Map<String, Object?> mcpServer({
  required String projectDir,
  required bool fvm,
}) {
  final args =
      projectDir.isEmpty
          ? ['run', 'localino_builder:mcp']
          : [
            'pub',
            '-C',
            projectDir,
            'run',
            'localino_builder:mcp',
            '--root',
            projectDir,
          ];

  return fvm
      ? {
        'command': 'fvm',
        'args': ['dart', ...args],
      }
      : {'command': 'dart', 'args': args};
}

/// [existing] `.mcp.json` text with [server] registered as `localino`; [existing]
/// unchanged when a `localino` server is already there. The entry is inserted as text so
/// the other servers keep their formatting; the result is re-encoded only when that
/// would not parse to the expected JSON.
String mergeMcpJson(String? existing, Map<String, Object?> server) {
  if (existing == null || existing.trim().isEmpty) {
    return _encode({
      'mcpServers': {_serverName: server},
    });
  }

  final data = jsonDecode(existing);

  if (data is! Map) {
    throw const FormatException('$mcpJsonPath is not a JSON object.');
  }

  final servers = data['mcpServers'];

  if (servers != null && servers is! Map) {
    throw const FormatException(
      '`mcpServers` in $mcpJsonPath is not an object.',
    );
  }

  if (servers is Map && servers.containsKey(_serverName)) {
    return existing;
  }

  final expected = {
    ...data,
    'mcpServers': {_serverName: server, ...?servers},
  };
  final match = RegExp(r'"mcpServers"\s*:\s*\{').firstMatch(existing);

  if (match != null) {
    final lineStart = existing.lastIndexOf('\n', match.start) + 1;
    final parentIndent =
        RegExp(r'^[ \t]*').firstMatch(existing.substring(lineStart))![0]!;
    final rest = existing.substring(match.end);
    final next = RegExp(r'^\s*').firstMatch(rest)![0]!;
    final empty = rest.substring(next.length).startsWith('}');
    final indent =
        !empty && next.contains('\n')
            ? next.substring(next.lastIndexOf('\n') + 1)
            : '$parentIndent  ';
    final newline = _newline(existing);
    final entry = '$newline$indent"$_serverName": ${_inline(server)}';
    final text =
        existing.substring(0, match.end) +
        (empty ? '$entry$newline$parentIndent' : '$entry,') +
        (empty ? rest.substring(next.length) : rest);

    if (_canonical(jsonDecode(text)) == _canonical(expected)) {
      return text;
    }
  }

  return _encode(expected);
}

/// The managed agent-rules block for [config]. [run] is the CLI prefix, [projectDir] the
/// project relative to the workspace root.
String rulesBlock(
  LocalinoConfig config, {
  required String run,
  required String projectDir,
  String? codegen,
}) {
  final from = projectDir.isEmpty ? '' : ' (from `$projectDir/`)';
  final assets =
      projectDir.isEmpty ? config.asset : '$projectDir/${config.asset}';
  final lock = projectDir.isEmpty ? lockPath : '$projectDir/$lockPath';
  final codegenStep =
      codegen == null
          ? "run the project's localization codegen"
          : 'run `$codegen`';

  return '''
$_blockBegin · managed by localino_builder init $packageVersion — edit outside this block; re-run init to update -->
## Syncing with Localino

`$assets` and the Localino project `${config.space}/${config.project}` are kept in sync by `localino_builder`: a three-way merge against `$lock` (committed), so local-only keys are never dropped and translator edits in the Localino console are never overwritten silently.

Commands$from:

```
$run status            # what differs (read-only)
$run pull              # Localino edits → locale files
$run push --dry-run    # what a push would send
$run push              # locale files → Localino (write key)
$run sync              # pull, then push
```

- ${codegen == null ? "**Codegen** after any change to the locale files: the project's localization codegen (pin it with `$run init --codegen \"<command>\"`)" : '**Codegen** after any change to the locale files: `$codegen`'}${config.generateKeys ? ' — `lib/generated/localino_keys.dart` is regenerated by localino_builder itself' : ''}.
- **Conflict** (both sides changed a key) → exit 3, nothing written. Ask whoever owns the copy, then re-run with `--prefer local` or `--prefer remote`.
- **Deletes** reach Localino only with `push --prune`.
- **A push is live**: apps with `LocalinoLive.options(remoteSync: true)` load pushed values without a release. Push reviewed copy only, dry run first.
- **Write key**: one per developer machine, created in the Localino console (project → key icon) and shown once. Store it with `$run login` and paste it on stdin. Never put it in the repo, `.mcp.json`, a chat or a command line.
- Commit `$lock` with the locale change it belongs to.
- **First sync** (no `$lock` yet) is done by a human in a terminal: `status`, then `sync`.

### Coding agents (MCP)

`.mcp.json` registers the `localino` MCP server. Tools: `localino_search_keys`, `localino_set_keys` (local files only), `localino_status`, `localino_pull`, `localino_push` (dry run by default).

1. `localino_search_keys` — reuse an existing key when the copy already exists.
2. `localino_set_keys` — add or change the key in every locale.
3. $codegenStep, then analyze and test.
4. `localino_push` (dry run) — show the plan to the user.
5. Only after the user confirms: `localino_push` with `dry_run: false`. Never pass `prefer`, resolve a conflict or run the first sync without asking.
$_blockEnd''';
}

/// [existing] rules with [block] in place of the managed block, or appended. The block
/// takes the file's line endings.
String applyRulesBlock(String? existing, String block) {
  if (existing == null || existing.trim().isEmpty) {
    return '$block\n';
  }

  final newline = _newline(existing);
  block = block.replaceAll('\n', newline);
  final start = existing.indexOf(_blockBegin);

  if (start < 0) {
    return '${existing.trimRight()}$newline$newline$block$newline';
  }

  final end = existing.indexOf(_blockEnd, start);

  if (end < 0) {
    throw const FormatException(
      'The Localino block in the agent rules has no `$_blockEnd` line.',
    );
  }

  return existing.replaceRange(start, end + _blockEnd.length, block);
}

/// Codegen command recorded by a previous block in [rules], or null.
String? previousCodegen(String? rules) =>
    rules == null
        ? null
        : _codegenLine.firstMatch(_insideBlock(rules))?.group(1);

String _insideBlock(String text) {
  final start = text.indexOf(_blockBegin);
  final end = text.indexOf(_blockEnd);

  return start < 0 || end < start ? '' : text.substring(start, end);
}

String _outsideBlock(String text) {
  final start = text.indexOf(_blockBegin);
  final end = text.indexOf(_blockEnd);

  return start < 0 || end < start
      ? text
      : text.replaceRange(start, end + _blockEnd.length, '');
}

bool _sameServer(String text, Map<String, Object?> server) =>
    _canonical((jsonDecode(text) as Map)['mcpServers']?[_serverName]) ==
    _canonical(server);

String _newline(String text) => text.contains('\r\n') ? '\r\n' : '\n';

String? _read(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

String _encode(Object? data) =>
    '${const JsonEncoder.withIndent('  ').convert(data)}\n';

/// One-line JSON with spaces after `:` and `,`, as hand-written `.mcp.json` files use.
String _inline(Object? value) => switch (value) {
  Map() =>
    '{${value.entries.map((e) => '${jsonEncode(e.key)}: ${_inline(e.value)}').join(', ')}}',
  List() => '[${value.map(_inline).join(', ')}]',
  _ => jsonEncode(value),
};

/// JSON with sorted keys, for order-independent comparison.
String _canonical(Object? value) => switch (value) {
  Map() =>
    '{${(value.keys.map((e) => '$e').toList()..sort()).map((k) => '${jsonEncode(k)}:${_canonical(value[k])}').join(',')}}',
  List() => '[${value.map(_canonical).join(',')}]',
  _ => jsonEncode(value),
};
