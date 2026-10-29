import 'merge.dart';

/// Locale → translation key → value, as read from the local locale files.
typedef LocalFiles = Map<String, Map<String, dynamic>>;

/// Absent, blank string, or an empty list / map.
bool isEmptyValue(Object? value) =>
    value == null ||
    (value is String && value.trim().isEmpty) ||
    (value is Map && value.isEmpty) ||
    (value is List && value.isEmpty);

/// Searches [files]: keys whose name or any value contains [query] (case-insensitive),
/// exact [keys], and/or keys missing or empty in [missingIn] — filters combine. Keys whose
/// value equals [query] come first (`exact_value_match`); `same_value_as` lists other keys
/// holding an identical value in the same locale, so an existing key can be reused.
Map<String, dynamic> searchKeys(
  LocalFiles files, {
  String? query,
  Set<String>? keys,
  String? missingIn,
  int limit = 20,
}) {
  final locales = files.keys.toList()..sort();
  final needle = query?.trim().toLowerCase();
  final allKeys = {for (final data in files.values) ...data.keys};

  final byValue = <String, Set<String>>{};
  for (final locale in locales) {
    for (final entry in files[locale]!.entries) {
      if (isEmptyValue(entry.value)) continue;
      (byValue['$locale\u0000${canonicalJson(entry.value)}'] ??= {}).add(
        entry.key,
      );
    }
  }

  final matches = <({String key, bool exactValue})>[];

  for (final key in allKeys.toList()..sort()) {
    if (keys != null && !keys.contains(key)) continue;
    if (missingIn != null && !isEmptyValue(files[missingIn]?[key])) continue;

    var exactValue = false;

    if (needle != null && needle.isNotEmpty) {
      final values = [
        for (final data in files.values)
          if (data[key] != null) data[key],
      ];
      exactValue = values.any(
        (value) => value is String && value.trim().toLowerCase() == needle,
      );

      if (!key.toLowerCase().contains(needle) &&
          !values.any((value) => _text(value).toLowerCase().contains(needle))) {
        continue;
      }
    }

    matches.add((key: key, exactValue: exactValue));
  }

  matches.sort((a, b) {
    if (a.exactValue != b.exactValue) return a.exactValue ? -1 : 1;
    return a.key.compareTo(b.key);
  });

  List<String> sameValue(String key) {
    final same = <String>{};

    for (final locale in locales) {
      final value = files[locale]![key];
      if (isEmptyValue(value)) continue;
      same.addAll(byValue['$locale\u0000${canonicalJson(value)}'] ?? const {});
    }

    return ((same..remove(key)).toList()..sort()).take(10).toList();
  }

  return {
    'locales': locales,
    'total': matches.length,
    'matches': [
      for (final match in matches.take(limit))
        {
          'key': match.key,
          'values': {
            for (final locale in locales)
              if (files[locale]!.containsKey(match.key))
                locale: files[locale]![match.key],
          },
          if (match.exactValue) 'exact_value_match': true,
          if (sameValue(match.key) case final same when same.isNotEmpty)
            'same_value_as': same,
        },
    ],
    if (matches.length > limit) 'truncated': true,
    if (keys != null)
      'not_found': keys.where((key) => !allKeys.contains(key)).toList()..sort(),
  };
}

/// Local edits planned by [planSetKeys]. Nothing is written when [errors] is non-empty.
class LocalChangePlan {
  final List<String> errors;

  /// Locale → key → new value.
  final LocalFiles sets;
  final Set<String> removes;

  /// `{locale, key, change: added|updated|removed, old?, new?}`.
  final List<Map<String, dynamic>> diff;

  /// `{key, missing_in}` for set keys left without a value in some local locale.
  final List<Map<String, dynamic>> incomplete;

  const LocalChangePlan({
    this.errors = const [],
    this.sets = const {},
    this.removes = const {},
    this.diff = const [],
    this.incomplete = const [],
  });

  bool get changed => diff.isNotEmpty;

  /// Locales whose file changes.
  Set<String> get locales => {
    for (final entry in diff) entry['locale'] as String,
  };
}

/// Plans setting [entries] (`key` → locale → value) and removing [removes] across
/// [files]. Keys must pass [isValidTranslationKey]; values must be strings, lists or
/// maps; locales must exist locally.
LocalChangePlan planSetKeys(
  LocalFiles files,
  List<({String key, Map<String, dynamic> values})> entries,
  Set<String> removes,
) {
  final locales = files.keys.toList()..sort();
  final sets = <String, Map<String, dynamic>>{};
  final errors = <String>[];

  for (final entry in entries) {
    if (!isValidTranslationKey(entry.key)) {
      errors.add('`${entry.key}`: invalid key (A-Z a-z 0-9 _ . -, max 200)');
    }

    if (removes.contains(entry.key)) {
      errors.add('`${entry.key}`: both set and removed');
    }

    for (final value in entry.values.entries) {
      if (!files.containsKey(value.key)) {
        errors.add('`${entry.key}`: unknown locale `${value.key}`');
      } else if (shapeOf(value.value) == null) {
        errors.add(
          '`${entry.key}` ${value.key}: value must be a string, list or map (use `remove` to delete)',
        );
      } else {
        (sets[value.key] ??= {})[entry.key] = value.value;
      }
    }
  }

  if (errors.isNotEmpty) {
    return LocalChangePlan(errors: errors);
  }

  final diff = <Map<String, dynamic>>[];

  for (final locale in locales) {
    final data = files[locale]!;

    for (final entry in (sets[locale] ?? const {}).entries) {
      if (!data.containsKey(entry.key)) {
        diff.add({
          'locale': locale,
          'key': entry.key,
          'change': 'added',
          'new': entry.value,
        });
      } else if (canonicalJson(data[entry.key]) != canonicalJson(entry.value)) {
        diff.add({
          'locale': locale,
          'key': entry.key,
          'change': 'updated',
          'old': data[entry.key],
          'new': entry.value,
        });
      }
    }

    for (final key in removes.where(data.containsKey)) {
      diff.add({
        'locale': locale,
        'key': key,
        'change': 'removed',
        'old': data[key],
      });
    }
  }

  return LocalChangePlan(
    sets: sets,
    removes: removes,
    diff: diff,
    incomplete: [
      for (final entry in entries)
        if ([
              for (final locale in locales)
                if (isEmptyValue(
                  sets[locale]?[entry.key] ?? files[locale]![entry.key],
                ))
                  locale,
            ]
            case final missing when missing.isNotEmpty)
          {'key': entry.key, 'missing_in': missing},
    ],
  );
}

String _text(Object? value) => value is String ? value : canonicalJson(value);
