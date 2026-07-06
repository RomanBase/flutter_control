import 'dart:io';

import 'key_model.dart';

/// Reports keys with no `LocalinoKeys.<name>` reference in Dart sources.
///
/// [libDir] is the root to scan (defaults to `./lib`). [generatedPath] is the
/// generated file to exclude from the scan. Returns the [LocalinoKey]s that are
/// never referenced. Report-only — never mutates sources.
List<LocalinoKey> findUnusedKeys(
  List<LocalinoKey> keys, {
  String libDir = './lib',
  String generatedPath = './lib/generated/localino_keys.dart',
}) {
  final dir = Directory(libDir);
  if (!dir.existsSync()) {
    return const [];
  }

  final generated = File(generatedPath).absolute.path;
  final source = StringBuffer();
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    if (entity.absolute.path == generated) {
      continue;
    }
    source
      ..write(entity.readAsStringSync())
      ..write('\n');
  }

  final haystack = source.toString();
  return [
    for (final key in keys)
      if (!_isReferenced(haystack, key.dartName)) key,
  ];
}

/// True if `LocalinoKeys.<name>` appears in [haystack] with a word boundary
/// after the name (so `action` doesn't match `action_add`).
bool _isReferenced(String haystack, String name) {
  final pattern = RegExp('LocalinoKeys\\.${RegExp.escape(name)}\\b');
  return pattern.hasMatch(haystack);
}
