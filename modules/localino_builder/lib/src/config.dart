import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const defaultAssetPath = 'assets/localization/{locale}.json';
const defaultApiUrl = 'https://api.localino.app/v1';
const setupJsonPath = 'assets/localization/setup.json';

class ConfigException implements Exception {
  final String message;

  const ConfigException(this.message);

  @override
  String toString() => message;
}

/// Resolved Localino project settings. [access] is the shared read token.
class LocalinoConfig {
  final String space;
  final String project;
  final String access;

  /// Locale file pattern relative to [root], e.g. `assets/localization/{locale}.json`.
  final String asset;
  final bool generateKeys;
  final bool reportUnused;

  /// Project root: `--root` or the nearest directory with a `pubspec.yaml`.
  final String root;

  const LocalinoConfig({
    required this.space,
    required this.project,
    required this.access,
    this.asset = defaultAssetPath,
    this.generateKeys = false,
    this.reportUnused = false,
    this.root = '.',
  });

  /// Builder options as accepted by `build(BuilderOptions(...))`.
  Map<String, dynamic> get options => {
    'space': space,
    'project': project,
    'access': access,
    'generate_keys': generateKeys,
    'report_unused': reportUnused,
  };

  @override
  String toString() =>
      'LocalinoConfig($space/$project, asset: $asset, root: $root)';
}

/// Value after the flag [name] in [args], or null.
String? option(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

/// `-u {access} -sp {space:project}`, or null when either flag is missing.
Map? parseArgs(List<String> args) {
  final access = option(args, '-u');
  final project = option(args, '-sp')?.split(':');

  if (access == null || project == null) {
    return null;
  }

  return {'access': access, 'space': project.first, 'project': project.last};
}

/// Finds `localino_builder` (or `localino_builder|localino_builder`) options in a parsed
/// `build.yaml`. Non-map values are skipped; `enabled: false` without options yields null.
Map? parseBuildYaml(dynamic data) {
  if (data is! Map) {
    return null;
  }

  for (final key in data.keys) {
    final value = data[key];

    if ((key == 'localino_builder' ||
            key == 'localino_builder|localino_builder') &&
        value is Map) {
      final options = value['options'];

      if (value['enabled'] == false || options is! Map) {
        return null;
      }

      return options;
    }
  }

  for (final value in data.values) {
    final options = parseBuildYaml(value);

    if (options != null) {
      return options;
    }
  }

  return null;
}

/// Nearest directory at or above [start] holding a `pubspec.yaml`, else [start].
String findProjectRoot(String start) {
  var dir = Directory(start).absolute;

  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }

    final parent = dir.parent;

    if (parent.path == dir.path) {
      return Directory(start).absolute.path;
    }

    dir = parent;
  }
}

/// `LOCALINO_API_URL` or [defaultApiUrl]. Plain http is refused except for local hosts,
/// so a redirected URL cannot capture the write key.
Uri resolveApiUrl(Map<String, String> env) {
  final raw = env['LOCALINO_API_URL'];
  final url = Uri.tryParse(raw == null || raw.isEmpty ? defaultApiUrl : raw);

  if (url == null || !url.hasAuthority) {
    throw ConfigException('Invalid LOCALINO_API_URL: $raw');
  }

  final local = url.host == 'localhost' || url.host == '127.0.0.1';

  if (url.scheme != 'https' && !(url.scheme == 'http' && local)) {
    throw ConfigException(
      'LOCALINO_API_URL must use https (http only for localhost): $raw',
    );
  }

  return url;
}

/// Loads config from CLI args, then `build.yaml`, then (with [setupFallback])
/// `assets/localization/setup.json` under [root]. `asset` defaults from `setup.json`.
/// Returns null when none is found.
///
/// The legacy download passes `setupFallback: false`: it overwrites the locale files, so
/// it runs only where args or `build.yaml` configure it explicitly.
LocalinoConfig? loadConfig({
  List<String> args = const [],
  required String root,
  bool setupFallback = true,
}) {
  final setup = _readJson('$root/$setupJsonPath');
  final buildYaml = File('$root/build.yaml');
  final options =
      parseArgs(args) ??
      (buildYaml.existsSync()
          ? parseBuildYaml(loadYaml(buildYaml.readAsStringSync()))
          : null) ??
      (setupFallback ? setup : null);

  if (options == null ||
      options['space'] == null ||
      options['project'] == null) {
    return null;
  }

  return LocalinoConfig(
    space: '${options['space']}',
    project: '${options['project']}',
    access: '${options['access'] ?? setup?['access'] ?? ''}',
    asset: '${options['asset'] ?? setup?['asset'] ?? defaultAssetPath}',
    generateKeys:
        _asBool(options['generate_keys']) || args.contains('--generate-keys'),
    reportUnused:
        _asBool(options['report_unused']) || args.contains('--report-unused'),
    root: root,
  );
}

Map? _readJson(String path) {
  final file = File(path);

  if (!file.existsSync()) {
    return null;
  }

  try {
    final data = jsonDecode(file.readAsStringSync());
    return data is Map ? data : null;
  } on FormatException {
    return null;
  }
}

/// `loadYaml` yields `YamlBool` or scalar strings, so accept both `true` and `'true'`.
bool _asBool(Object? value) => value == true || value == 'true';
