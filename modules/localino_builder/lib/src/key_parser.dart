import 'key_model.dart';

/// Dart reserved words that cannot be used as identifiers. Sanitizing to any of
/// these appends a trailing `_`.
const _reservedWords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

/// `Object`/type members an `abstract final class` inherits — reusing these as
/// const names shadows the member and warns, so append a trailing `_`.
const _memberNames = <String>{
  'hashCode',
  'runtimeType',
  'toString',
  'noSuchMethod',
  'values',
};

final _paramPattern = RegExp(r'\{(\w+)\}');
final _nonIdentPattern = RegExp(r'[^A-Za-z0-9_]');

/// Parses decoded locale maps into a sorted list of [LocalinoKey].
///
/// [localesByCode] maps each locale code to its decoded JSON map.
/// [defaultLocale] selects which locale supplies previews and the key universe
/// for missing-locale detection.
///
/// Throws [StateError] if [defaultLocale] is absent, or if two distinct JSON
/// keys sanitize to the same Dart identifier.
List<LocalinoKey> parseLocalinoKeys(
  Map<String, Map> localesByCode, {
  required String defaultLocale,
}) {
  final defaultMap = localesByCode[defaultLocale];
  if (defaultMap == null) {
    throw StateError(
      'Default locale "$defaultLocale" not found among '
      '${localesByCode.keys.toList()}.',
    );
  }

  final otherLocales = localesByCode.keys.where((l) => l != defaultLocale);

  final sortedJsonKeys = defaultMap.keys.map((k) => k.toString()).toList()
    ..sort();

  final result = <LocalinoKey>[];
  final claimedNames = <String, String>{}; // dartName -> jsonKey

  for (final jsonKey in sortedJsonKeys) {
    final value = defaultMap[jsonKey];
    final kind = inferKind(value);

    final dartName = sanitizeIdentifier(jsonKey);
    final owner = claimedNames[dartName];
    if (owner != null) {
      throw StateError(
        'Localino key collision: "$owner" and "$jsonKey" both sanitize to '
        '"$dartName". Rename one JSON key.',
      );
    }
    claimedNames[dartName] = jsonKey;

    final missing = [
      for (final locale in otherLocales)
        if (!(localesByCode[locale]?.containsKey(jsonKey) ?? false)) locale,
    ]..sort();

    result.add(LocalinoKey(
      jsonKey: jsonKey,
      dartName: dartName,
      kind: kind,
      params: kind == LocalinoKeyKind.format ? extractParams(value) : const [],
      preview: buildPreview(value),
      missingLocales: missing,
    ));
  }

  return result;
}

/// Infers the [LocalinoKeyKind] of a decoded JSON [value].
LocalinoKeyKind inferKind(Object? value) {
  if (value is Map) {
    return LocalinoKeyKind.map;
  }
  if (value is List) {
    return LocalinoKeyKind.list;
  }
  final str = value?.toString() ?? '';
  return _paramPattern.hasMatch(str)
      ? LocalinoKeyKind.format
      : LocalinoKeyKind.string;
}

/// Extracts `{param}` names, in order, from a format-string [value].
List<String> extractParams(Object? value) {
  final str = value?.toString() ?? '';
  return [for (final m in _paramPattern.allMatches(str)) m.group(1)!];
}

/// Sanitizes a JSON key into a valid, non-clashing Dart const identifier.
String sanitizeIdentifier(String jsonKey) {
  var name = jsonKey.replaceAll(_nonIdentPattern, '_');

  if (name.isEmpty) {
    name = 'k';
  } else if (RegExp(r'^[0-9]').hasMatch(name)) {
    name = 'k$name';
  }

  if (_reservedWords.contains(name) || _memberNames.contains(name)) {
    name = '${name}_';
  }

  return name;
}

/// Builds a one-line doc preview: newline-stripped, collapsed whitespace,
/// truncated to ~60 chars with an ellipsis.
String buildPreview(Object? value) {
  if (value is Map || value is List) {
    return '';
  }
  final raw = value?.toString() ?? '';
  final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  const max = 60;
  if (collapsed.length <= max) {
    return collapsed;
  }
  return '${collapsed.substring(0, max).trimRight()}…';
}

/// Resolves the default locale from decoded `setup.json`.
///
/// Precedence mirrors `LocalinoConfig.fallbackLocale`: `init.default_locale`
/// if present, else the first key of `locales`. Throws [StateError] if neither
/// yields a locale.
String resolveDefaultLocale(Map setupJson) {
  final init = setupJson['init'];
  if (init is Map) {
    final explicit = init['default_locale'];
    if (explicit is String && explicit.isNotEmpty) {
      return explicit;
    }
  }

  final locales = setupJson['locales'];
  if (locales is Map && locales.isNotEmpty) {
    return locales.keys.first.toString();
  }

  throw StateError(
    'Cannot resolve default locale: no init.default_locale and no locales.',
  );
}
