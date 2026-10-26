@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:test/test.dart';

const _inbook = 'test/fixtures/sync/inbook';
final _cli = File('bin/localino_builder.dart').absolute.path;

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('localino_cli');
    for (final file in Directory(_inbook).listSync(recursive: true)) {
      if (file is! File) continue;
      final target = File(
        '${root.path}/${file.path.substring(_inbook.length + 1)}',
      )..createSync(recursive: true);
      target.writeAsBytesSync(file.readAsBytesSync());
    }
    File('${root.path}/pubspec.yaml').writeAsStringSync('name: consumer\n');
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult> run(List<String> args, {String? stdin}) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', _cli, ...args],
      workingDirectory: root.path,
      environment: {
        'HOME': root.path,
        // Closed local port: any network call fails fast instead of reaching Localino.
        'LOCALINO_API_URL': 'http://127.0.0.1:9/v1',
      },
    );
    if (stdin != null) process.stdin.writeln(stdin);
    await process.stdin.close();

    return ProcessResult(
      process.pid,
      await process.exitCode,
      await process.stdout.transform(const SystemEncoding().decoder).join(),
      await process.stderr.transform(const SystemEncoding().decoder).join(),
    );
  }

  test(
    'legacy download ignores setup.json when build.yaml disables the builder',
    () async {
      final locale = File('${root.path}/assets/localization/cs_CZ.json');
      final before = locale.readAsStringSync();

      final result = await run([]);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('Localino Config Not Found'));
      expect(locale.readAsStringSync(), before);
    },
  );

  test('an invalid --prefer exits 1', () async {
    final result = await run(['sync', '--prefer', 'mine']);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('--prefer must be'));
  });

  test('an option the command does not take exits 1 before any work', () async {
    final locale = File('${root.path}/assets/localization/cs_CZ.json');
    final before = locale.readAsStringSync();

    for (final (args, message) in [
      (['sync', '--dry-run'], '`sync` does not accept `--dry-run`'),
      (['push', '--dryrun'], '`push` does not accept `--dryrun`'),
      (['pull', '--prune'], '`pull` does not accept `--prune`'),
      (['pull', '--prefer'], '`--prefer` needs a value'),
    ]) {
      final result = await run(args);

      expect(result.exitCode, 1, reason: '$args');
      expect(result.stderr, contains(message), reason: '$args');
    }
    expect(locale.readAsStringSync(), before);
    expect(Directory('${root.path}/.localino').existsSync(), isFalse);
  });

  test('every documented push option is accepted', () async {
    final result = await run([
      'push',
      '--dry-run',
      '--prune',
      '--prefer',
      'local',
      '--root',
      root.path,
    ]);

    // Past option checks: fails only for the missing write key.
    expect(result.exitCode, 4, reason: '${result.stderr}');
  });

  test('a missing config exits 1', () async {
    File('${root.path}/assets/localization/setup.json').deleteSync();

    final result = await run(['status']);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('config not found'));
  });

  test('a malformed lock file exits 1, not with a stack trace', () async {
    File('${root.path}/.localino/lock.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');

    final result = await run(['status']);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Invalid file content'));
  });

  test('login rejects a value that is not a write key', () async {
    final result = await run(['login'], stdin: 'not-a-key');

    expect(result.exitCode, 4);
    expect(
      File('${root.path}/.localino/credentials.json').existsSync(),
      isFalse,
    );
  });
}
