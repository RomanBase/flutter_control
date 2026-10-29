import 'dart:io';

import 'package:localino_builder/src/key_model.dart';
import 'package:localino_builder/src/unused_reporter.dart';
import 'package:test/test.dart';

void main() {
  const keys = [
    LocalinoKey(
      jsonKey: 'action_add',
      dartName: 'action_add',
      kind: LocalinoKeyKind.string,
    ),
    LocalinoKey(
      jsonKey: 'action_remove',
      dartName: 'action_remove',
      kind: LocalinoKeyKind.string,
    ),
    LocalinoKey(
      jsonKey: 'action',
      dartName: 'action',
      kind: LocalinoKeyKind.string,
    ),
  ];

  late Directory root;
  late String libDir;
  late String generatedPath;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('localino_unused_');
    libDir = '${root.path}/lib';
    generatedPath = '$libDir/generated/localino_keys.dart';
    Directory('$libDir/generated').createSync(recursive: true);
    // Generated file references every key — must be excluded from the scan.
    File(generatedPath).writeAsStringSync(
      keys
          .map((k) =>
              "static const ${k.dartName} = 'x'; // LocalinoKeys.${k.dartName}")
          .join('\n'),
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('referenced key is not reported', () {
    File('$libDir/app.dart').writeAsStringSync(
      'final x = LocalinoKeys.action_add;\n',
    );

    final unused = findUnusedKeys(
      keys,
      libDir: libDir,
      generatedPath: generatedPath,
    );
    final names = unused.map((k) => k.jsonKey);
    expect(names, isNot(contains('action_add')));
  });

  test('unreferenced key is reported', () {
    File('$libDir/app.dart').writeAsStringSync(
      'final x = LocalinoKeys.action_add;\n',
    );

    final unused = findUnusedKeys(
      keys,
      libDir: libDir,
      generatedPath: generatedPath,
    );
    expect(unused.map((k) => k.jsonKey), contains('action_remove'));
  });

  test('word-boundary: LocalinoKeys.action_add does not mark action used', () {
    File('$libDir/app.dart').writeAsStringSync(
      'final x = LocalinoKeys.action_add;\n',
    );

    final unused = findUnusedKeys(
      keys,
      libDir: libDir,
      generatedPath: generatedPath,
    );
    expect(unused.map((k) => k.jsonKey), contains('action'));
  });

  test('generated file is excluded from scan', () {
    // No app.dart references anything; only the generated file mentions keys.
    final unused = findUnusedKeys(
      keys,
      libDir: libDir,
      generatedPath: generatedPath,
    );
    expect(unused.length, keys.length);
  });
}
