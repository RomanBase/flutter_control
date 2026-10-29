/// Kind of a localization value, used only to pick the doc-comment label.
///
/// The generated `static const` is `<name> = '<jsonKey>'` regardless of kind —
/// kind never changes the emitted value, only its documentation.
enum LocalinoKeyKind {
  /// Plain string with no `{param}` placeholders.
  string,

  /// String containing one or more `{param}` placeholders.
  format,

  /// Any JSON object (plural, value-switch, or nested map).
  map,

  /// JSON array.
  list,
}

/// Immutable description of a single localization key across all locales.
class LocalinoKey {
  /// Runtime lookup key, verbatim from JSON — never mangled.
  final String jsonKey;

  /// Sanitized Dart const identifier derived from [jsonKey].
  final String dartName;

  /// Value shape, drives the doc-comment label only.
  final LocalinoKeyKind kind;

  /// Format param names in order, e.g. `['version', 'number']`. Empty unless
  /// [kind] is [LocalinoKeyKind.format].
  final List<String> params;

  /// Default-locale value, truncated and newline-stripped, for the doc comment.
  final String preview;

  /// Locales that lack this key (present in default locale, absent elsewhere).
  final List<String> missingLocales;

  const LocalinoKey({
    required this.jsonKey,
    required this.dartName,
    required this.kind,
    this.params = const [],
    this.preview = '',
    this.missingLocales = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalinoKey &&
          runtimeType == other.runtimeType &&
          jsonKey == other.jsonKey &&
          dartName == other.dartName &&
          kind == other.kind &&
          _listEquals(params, other.params) &&
          preview == other.preview &&
          _listEquals(missingLocales, other.missingLocales);

  @override
  int get hashCode => Object.hash(
        jsonKey,
        dartName,
        kind,
        Object.hashAll(params),
        preview,
        Object.hashAll(missingLocales),
      );

  @override
  String toString() =>
      'LocalinoKey($jsonKey -> $dartName, $kind, params: $params, '
      'missing: $missingLocales)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
