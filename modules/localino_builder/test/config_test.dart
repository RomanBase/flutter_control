import 'dart:io';

import 'package:localino_builder/src/config.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

const _inbook = 'test/fixtures/sync/inbook';

void main() {
  group('parseBuildYaml', () {
    test('inbook-style `enabled: false` yields no options', () {
      final yaml = loadYaml(File('$_inbook/build.yaml').readAsStringSync());
      expect(parseBuildYaml(yaml), isNull);
    });

    test('accepts `localino_builder|localino_builder` key', () {
      final yaml = loadYaml('''
targets:
  \$default:
    builders:
      localino_builder|localino_builder:
        options:
          space: s
          project: p
''');
      expect(parseBuildYaml(yaml), {'space': 's', 'project': 'p'});
    });

    test('accepts plain `localino_builder` key and skips non-map values', () {
      final yaml = loadYaml('''
targets:
  \$default:
    sources: [lib/**]
    builders:
      other: true
      localino_builder:
        options:
          space: s
          project: p
          access: a
''');
      expect(parseBuildYaml(yaml), {
        'space': 's',
        'project': 'p',
        'access': 'a',
      });
    });
  });

  group('loadConfig', () {
    test('inbook-style build.yaml falls back to setup.json', () {
      final config = loadConfig(root: _inbook)!;

      expect(config.space, 'insight');
      expect(config.project, 'inbook');
      expect(config.access, 'read-token');
      expect(config.asset, 'assets/localization/{locale}.json');
      expect(config.root, _inbook);
    });

    test('CLI args win over files', () {
      final config =
          loadConfig(
            args: ['-u', 'tok', '-sp', 'a:b', '--generate-keys'],
            root: _inbook,
          )!;

      expect(config.space, 'a');
      expect(config.project, 'b');
      expect(config.access, 'tok');
      expect(config.generateKeys, isTrue);
    });

    test('no config → null', () {
      final dir = Directory.systemTemp.createTempSync('localino_config');
      addTearDown(() => dir.deleteSync(recursive: true));

      expect(loadConfig(root: dir.path), isNull);
    });
  });

  test('parseArgs needs both flags', () {
    expect(parseArgs(['-u', 'tok']), isNull);
    expect(parseArgs(['-u']), isNull);
    expect(parseArgs(['-u', 'tok', '-sp', 'space:project']), {
      'access': 'tok',
      'space': 'space',
      'project': 'project',
    });
  });

  test('findProjectRoot walks up to pubspec.yaml', () {
    final dir = Directory.systemTemp.createTempSync('localino_root');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/pubspec.yaml').writeAsStringSync('name: x');
    final nested = Directory('${dir.path}/lib/src')
      ..createSync(recursive: true);

    expect(findProjectRoot(nested.path), dir.absolute.path);
  });

  group('resolveApiUrl', () {
    test('defaults to production https', () {
      expect(resolveApiUrl({}).toString(), defaultApiUrl);
    });

    test('allows http only for localhost', () {
      expect(
        resolveApiUrl({'LOCALINO_API_URL': 'http://localhost:8080/v1'}).host,
        'localhost',
      );
      expect(
        resolveApiUrl({'LOCALINO_API_URL': 'http://127.0.0.1:8080/v1'}).host,
        '127.0.0.1',
      );
      expect(
        () => resolveApiUrl({'LOCALINO_API_URL': 'http://evil.example/v1'}),
        throwsA(isA<ConfigException>()),
      );
      expect(
        () => resolveApiUrl({'LOCALINO_API_URL': 'ftp://localhost/v1'}),
        throwsA(isA<ConfigException>()),
      );
    });
  });
}
