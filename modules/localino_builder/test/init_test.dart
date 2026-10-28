import 'dart:convert';
import 'dart:io';

import 'package:localino_builder/src/config.dart';
import 'package:localino_builder/src/init/project_init.dart';
import 'package:test/test.dart';

const _server = {
  'command': 'dart',
  'args': ['run', 'localino_builder:mcp'],
};

/// `.mcp.json` as portmonka writes it: expanded arrays, 2-space indent.
const _expanded = '''
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": [
        "mcp-server"
      ]
    },
    "Sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp/acme/app"
    }
  }
}
''';

/// `.mcp.json` as inbook writes it: inline arrays, 4-space entries.
const _inline = '''
{
  "mcpServers": {
    "playwright": {
      "command": "npx.cmd",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
''';

void main() {
  group('mergeMcpJson', () {
    test('creates the file when there is none', () {
      final text = mergeMcpJson(null, _server);

      expect(jsonDecode(text), {
        'mcpServers': {'localino': _server},
      });
      expect(text, endsWith('}\n'));
    });

    for (final (name, existing) in [
      ('expanded', _expanded),
      ('inline', _inline),
    ]) {
      test('adds the server and keeps every $name line of the others', () {
        final text = mergeMcpJson(existing, _server);
        final data = jsonDecode(text) as Map;
        final before = jsonDecode(existing) as Map;

        expect(data['mcpServers']['localino'], _server);
        expect(
          (data['mcpServers'] as Map)..remove('localino'),
          before['mcpServers'],
        );
        expect(
          text.split('\n').where((line) => !line.contains('localino')),
          existing.split('\n'),
        );
        expect(
          text,
          contains(
            '    "localino": {"command": "dart", "args": ["run", "localino_builder:mcp"]},\n',
          ),
        );
      });
    }

    test('fills an empty mcpServers object', () {
      final text = mergeMcpJson('{\n  "mcpServers": {}\n}\n', _server);

      expect(
        text,
        '{\n  "mcpServers": {\n    "localino": {"command": "dart", "args": ["run", "localino_builder:mcp"]}\n  }\n}\n',
      );
    });

    test('adds mcpServers next to other settings', () {
      final text = mergeMcpJson('{"other": 1}', _server);

      expect(jsonDecode(text), {
        'other': 1,
        'mcpServers': {'localino': _server},
      });
    });

    test('keeps an existing localino entry untouched', () {
      const existing =
          '{"mcpServers": {"localino": {"command": "custom", "args": []}}}';

      expect(mergeMcpJson(existing, _server), existing);
    });

    test('a file that is not a JSON object is an error', () {
      expect(() => mergeMcpJson('[]', _server), throwsFormatException);
      expect(() => mergeMcpJson('{nope', _server), throwsFormatException);
      expect(
        () => mergeMcpJson('{"mcpServers": []}', _server),
        throwsFormatException,
      );
    });
  });

  group('mcpServer', () {
    test(
      'runs from the project root, through fvm when the project uses it',
      () {
        expect(mcpServer(projectDir: '', fvm: false), _server);
        expect(mcpServer(projectDir: '', fvm: true), {
          'command': 'fvm',
          'args': ['dart', 'run', 'localino_builder:mcp'],
        });
      },
    );

    test('a nested project runs through `dart pub -C` with --root', () {
      expect(mcpServer(projectDir: 'main_tablet', fvm: false), {
        'command': 'dart',
        'args': [
          'pub',
          '-C',
          'main_tablet',
          'run',
          'localino_builder:mcp',
          '--root',
          'main_tablet',
        ],
      });
    });
  });

  group('rules block', () {
    const config = LocalinoConfig(space: 'sp', project: 'pr', access: 'uid');

    String block({String? codegen, String projectDir = ''}) => rulesBlock(
      config,
      run: 'fvm dart run localino_builder',
      projectDir: projectDir,
      codegen: codegen,
    );

    test('names the project, the commands and the codegen', () {
      final text = block(codegen: 'cd ci && dart run bin/localino.dart');

      expect(text, startsWith('<!-- localino:begin'));
      expect(text, endsWith('<!-- localino:end -->'));
      expect(text, contains('`sp/pr`'));
      expect(text, contains('fvm dart run localino_builder push --dry-run'));
      expect(text, contains('run `cd ci && dart run bin/localino.dart`'));
      expect(text, isNot(contains('uid')));
      expect(previousCodegen(text), 'cd ci && dart run bin/localino.dart');
    });

    test('without codegen tells how to pin one', () {
      final text = block();

      expect(text, contains('init --codegen'));
      expect(previousCodegen(text), isNull);
    });

    test('a nested project names its directory', () {
      final text = block(projectDir: 'main_tablet');

      expect(text, contains('`main_tablet/assets/localization/{locale}.json`'));
      expect(text, contains('Commands (from `main_tablet/`)'));
      expect(text, contains('`main_tablet/.localino/lock.json`'));
    });

    test('is appended once, then replaced in place', () {
      const head = '# Localization\n\nHand-written rules.\n';
      const tail = '\n## Afterwards\n\nMore rules.\n';

      final first = applyRulesBlock(head, block(codegen: 'a'));
      expect(first, startsWith('$head\n<!-- localino:begin'));
      expect(first, endsWith('<!-- localino:end -->\n'));

      final edited = '$first$tail';
      final second = applyRulesBlock(edited, block(codegen: 'b'));

      expect(second, startsWith('$head\n<!-- localino:begin'));
      expect(second, endsWith('<!-- localino:end -->\n$tail'));
      expect(second, contains('run `b`'));
      expect(second, isNot(contains('run `a`')));
      expect(applyRulesBlock(second, block(codegen: 'b')), second);
    });

    test('a block without its end line is an error', () {
      expect(
        () => applyRulesBlock('<!-- localino:begin -->\nhalf', block()),
        throwsFormatException,
      );
    });
  });

  group('planInit', () {
    late Directory repo;

    setUp(() {
      repo = Directory.systemTemp.createTempSync('localino_init');
      Directory('${repo.path}/.git').createSync();
    });

    tearDown(() => repo.deleteSync(recursive: true));

    void write(String path, String text) =>
        File('${repo.path}/$path')
          ..createSync(recursive: true)
          ..writeAsStringSync(text);

    String? read(String path) {
      final file = File('${repo.path}/$path');
      return file.existsSync() ? file.readAsStringSync() : null;
    }

    LocalinoConfig config([String dir = '']) => LocalinoConfig(
      space: 'sp',
      project: 'pr',
      access: 'uid',
      root: dir.isEmpty ? repo.path : '${repo.path}/$dir',
    );

    test(
      'a project like portmonka: fvm, rules/localization.md, other MCP servers',
      () {
        write('.fvmrc', '{"flutter": "3.47.5"}');
        write('.mcp.json', _expanded);
        write('rules/localization.md', '# Localization\n');
        write('AGENTS.md', '- [localization.md](rules/localization.md)\n');

        final plan = planInit(
          config(),
          codegen: 'cd ci && dart run bin/localino.dart',
        );
        plan.apply();

        expect(plan.projectDir, '');
        expect(plan.run, 'fvm dart run localino_builder');
        expect(plan.warnings, isEmpty);
        expect(jsonDecode(read('.mcp.json')!)['mcpServers']['localino'], {
          'command': 'fvm',
          'args': ['dart', 'run', 'localino_builder:mcp'],
        });
        expect(
          read('rules/localization.md'),
          startsWith('# Localization\n\n<!-- localino:begin'),
        );
        expect(
          read('AGENTS.md'),
          '- [localization.md](rules/localization.md)\n',
        );

        final again = planInit(config());

        expect(again.files.where((e) => e.changed), isEmpty);
        expect(again.server, isNull);
        expect(
          previousCodegen(read('rules/localization.md')),
          'cd ci && dart run bin/localino.dart',
        );
      },
    );

    test('a nested app like petra: .mcp.json and rules at the git root', () {
      write('rules/localization.md', '# Localization\n');
      write('CLAUDE.md', 'Read rules/localization.md.\n');
      write('main_tablet/pubspec.yaml', 'name: app\n');

      final plan = planInit(config('main_tablet'))..apply();

      expect(plan.projectDir, 'main_tablet');
      expect(plan.run, 'dart run localino_builder');
      expect(plan.mcpJson.before, isNull);
      expect(jsonDecode(read('.mcp.json')!)['mcpServers']['localino']['args'], [
        'pub',
        '-C',
        'main_tablet',
        'run',
        'localino_builder:mcp',
        '--root',
        'main_tablet',
      ]);
      expect(
        read('rules/localization.md'),
        contains('Commands (from `main_tablet/`)'),
      );
      expect(read('main_tablet/.mcp.json'), isNull);
    });

    test('without rule files it creates CLAUDE.md; --rules picks the file', () {
      expect(planInit(config()).rules.path, 'CLAUDE.md');

      write('AGENTS.md', '# Agents\n');
      expect(planInit(config()).rules.path, 'AGENTS.md');
      expect(
        planInit(config(), rules: 'docs/agents.md').rules.path,
        'docs/agents.md',
      );
    });

    test(
      'warns about hand-written sync rules, unreferenced rules and a custom server',
      () {
        write(
          'rules/localization.md',
          '## Syncing\n\n`localino_builder sync`\n',
        );
        write(
          '.mcp.json',
          '{"mcpServers": {"localino": {"command": "custom"}}}',
        );

        final plan = planInit(config());

        expect(plan.server, isNull);
        expect(plan.mcpJson.changed, false);
        expect(plan.warnings, [
          contains('already registers `localino` differently'),
          contains('outside the managed block'),
          contains(
            'Neither AGENTS.md nor CLAUDE.md mentions rules/localization.md',
          ),
        ]);
      },
    );

    test('a codegen command with backticks is refused', () {
      expect(
        () => planInit(config(), codegen: 'run `this`'),
        throwsA(isA<ConfigException>()),
      );
    });
  });
}
