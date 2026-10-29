import 'dart:convert';
import 'dart:io';

import 'merge.dart';

const lockPath = '.localino/lock.json';
const lockVersion = 1;
const writeKeyEnv = 'LOCALINO_WRITE_KEY';

final writeKeyPattern = RegExp(r'^lk_w_([0-9A-Za-z]{12})_([0-9A-Za-z]{43})$');

/// A decoded locale file plus the formatting needed to write it back unchanged.
class LocaleFile {
  /// Translation key → value, in file order.
  final Map<String, dynamic> data;
  final String indent;
  final bool trailingNewline;

  const LocaleFile(
    this.data, {
    this.indent = '  ',
    this.trailingNewline = true,
  });
}

/// Reads a locale JSON file. A missing file reads as empty with [fallbackIndent].
LocaleFile readLocaleFile(File file, {String fallbackIndent = '  '}) {
  if (!file.existsSync()) {
    return LocaleFile({}, indent: fallbackIndent);
  }

  final text = file.readAsStringSync();
  final data = jsonDecode(text);

  if (data is! Map) {
    throw FormatException('Locale file is not a JSON object: ${file.path}');
  }

  return LocaleFile(
    Map<String, dynamic>.from(data),
    indent: detectIndent(text) ?? fallbackIndent,
    trailingNewline: text.endsWith('\n'),
  );
}

/// Indent of the first indented line, or null for single-line JSON.
String? detectIndent(String text) {
  final match = RegExp(r'\n([ \t]+)\S').firstMatch(text);
  return match?.group(1);
}

/// Applies [sets] (key → value) and [removes] to [data]: existing keys keep their order,
/// new keys are appended sorted.
Map<String, dynamic> applyLocaleChanges(
  Map<String, dynamic> data,
  Map<String, dynamic> sets,
  Set<String> removes,
) {
  final result = <String, dynamic>{};

  for (final entry in data.entries) {
    if (removes.contains(entry.key)) continue;
    result[entry.key] =
        sets.containsKey(entry.key) ? sets[entry.key] : entry.value;
  }

  final added =
      sets.keys
          .where((key) => !data.containsKey(key) && !removes.contains(key))
          .toList()
        ..sort();

  for (final key in added) {
    result[key] = sets[key];
  }

  return result;
}

/// UTF-8 JSON without ASCII escaping. Same input → same bytes.
String encodeLocale(LocaleFile file) {
  final text = JsonEncoder.withIndent(file.indent).convert(file.data);
  return file.trailingNewline ? '$text\n' : text;
}

void writeLocaleFile(File file, LocaleFile data) =>
    _writeIfChanged(file, encodeLocale(data));

/// Reads `.localino/lock.json`; a missing file is an empty lock.
Lock readLock(File file) {
  if (!file.existsSync()) {
    return Lock({});
  }

  final data = jsonDecode(file.readAsStringSync());

  if (data is! Map ||
      data['version'] != lockVersion ||
      data['locales'] is! Map) {
    throw FormatException('Unsupported lock file: ${file.path}');
  }

  return Lock({
    for (final locale in (data['locales'] as Map).entries)
      '${locale.key}': {
        for (final key in (locale.value as Map).entries)
          '${key.key}': LockEntry(
            key.value['h'] as String,
            (key.value['ts'] as num).toInt(),
          ),
      },
  });
}

/// Writes the lock sorted by locale and key; unchanged content is not rewritten.
void writeLock(File file, Lock lock) {
  final locales =
      lock.locales.keys
          .where((locale) => lock.locales[locale]!.isNotEmpty)
          .toList()
        ..sort();

  final data = {
    'version': lockVersion,
    'locales': {
      for (final locale in locales)
        locale: {
          for (final key in lock.locales[locale]!.keys.toList()..sort())
            key: {
              'h': lock.locales[locale]![key]!.h,
              'ts': lock.locales[locale]![key]!.ts,
            },
        },
    },
  };

  _writeIfChanged(
    file,
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
}

void _writeIfChanged(File file, String text) {
  if (file.existsSync() && file.readAsStringSync() == text) {
    return;
  }

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(text);
}

/// A per-project write key. [toString] never reveals the secret.
class WriteKey {
  final String value;

  const WriteKey(this.value);

  String get keyId => writeKeyPattern.firstMatch(value)?.group(1) ?? '?';

  static bool isValid(String value) => writeKeyPattern.hasMatch(value);

  @override
  String toString() => 'WriteKey(lk_w_${keyId}_***)';
}

/// `~/.localino/credentials.json`, or null when no home directory is known.
String? defaultCredentialsPath(Map<String, String> env) {
  final home = env['HOME'] ?? env['USERPROFILE'];
  return home == null ? null : '$home/.localino/credentials.json';
}

/// Write key for `space/project`: `LOCALINO_WRITE_KEY` first, then the credentials file.
WriteKey? readWriteKey(
  String space,
  String project, {
  required Map<String, String> env,
  String? credentialsPath,
}) {
  final fromEnv = env[writeKeyEnv];

  if (fromEnv != null && fromEnv.isNotEmpty) {
    return WriteKey(fromEnv.trim());
  }

  if (credentialsPath == null || !File(credentialsPath).existsSync()) {
    return null;
  }

  final data = jsonDecode(File(credentialsPath).readAsStringSync());
  final value = data is Map ? data['$space/$project'] : null;

  return value is String && value.isNotEmpty ? WriteKey(value) : null;
}

/// Stores [key] for `space/project`: temp file → chmod 600 → rename, so the key is
/// never readable by others, even briefly.
void storeWriteKey(
  String space,
  String project,
  WriteKey key, {
  required String credentialsPath,
}) {
  final file = File(credentialsPath);
  final existing =
      file.existsSync() ? jsonDecode(file.readAsStringSync()) : null;
  final data = {if (existing is Map) ...existing, '$space/$project': key.value};

  file.parent.createSync(recursive: true);
  _chmod('700', file.parent.path);

  final temp = File('$credentialsPath.tmp');
  temp.writeAsStringSync('');
  _chmod('600', temp.path);
  temp.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
  temp.renameSync(credentialsPath);
}

void _chmod(String mode, String path) {
  if (Platform.isWindows) return;

  final result = Process.runSync('chmod', [mode, path]);

  if (result.exitCode != 0) {
    throw FileSystemException('chmod $mode failed: ${result.stderr}', path);
  }
}
