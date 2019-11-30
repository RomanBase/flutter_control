import 'dart:convert';

import 'package:flutter_control/core.dart';

/// Helps to parse basic objects.
class Parse {
  /// Tries to parse value into integer.
  ///
  /// null, int, double, bool, String
  ///
  /// If none found, then [defaultValue] is returned.
  static int toInteger(dynamic value, {int defaultValue: 0}) {
    if (value is int) {
      return value;
    }

    if (value == null) {
      return defaultValue;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is bool) {
      return value ? 1 : 0;
    }

    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }

    return defaultValue;
  }

  /// Tries to parse value into double.
  ///
  /// null, int, double, bool, String.
  ///
  /// If none found, then [defaultValue] is returned.
  static double toDouble(dynamic value, {double defaultValue: 0.0}) {
    if (value is double) {
      return value;
    }

    if (value == null) {
      return defaultValue;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is bool) {
      return value ? 1.0 : 0.0;
    }

    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }

    return defaultValue;
  }

  /// Tries to parse value into bool.
  ///
  /// null, int, double, bool, String.
  ///
  /// If none found, then [defaultValue] is returned.
  static bool toBool(dynamic value, {bool defaultValue: false}) {
    if (value is bool) {
      return value;
    }

    if (value == null) {
      return defaultValue;
    }

    final num = toInteger(value, defaultValue: -1);

    if (num > -1) {
      return num > 0;
    }

    return defaultValue;
  }

  /// Tries to parse value into List.
  ///
  /// List, Map, Iterable.
  ///
  /// Use [ValueConverter] to convert values into new List.
  /// Use [hardCast] if you are sure that [value] contains expected Types and there is no need to convert items.
  static List<T> toList<T>(dynamic value, {ValueConverter<T> converter, bool hardCast: true}) {
    final items = List<T>();

    if (value == null) {
      return items;
    }

    if (value is Map) {
      value = value.values;
    }

    if (value is Iterable) {
      if (converter == null) {
        if (value is List && hardCast) {
          return value.cast<T>();
        }

        value.forEach((item) {
          if (item is T) {
            items.add(item);
          }
        });
      } else {
        value.forEach((item) {
          final listItem = converter(item);

          if (listItem != null && listItem is T) {
            items.add(listItem);
          }
        });
      }
    } else {
      if (converter == null) {
        if (value is T) {
          items.add(value);
        } else {
          final listItem = converter(value);

          if (listItem != null && listItem is T) {
            items.add(listItem);
          }
        }
      }
    }

    return items;
  }

  /// Tries to parse value into List.
  /// If converter is not specified [Parse.toList] is used instead.
  ///
  /// List, Map, Iterable.
  ///
  /// Use [PairConverter] to convert values into new List.
  /// Use [hardCast] if you are sure that [value] contains expected Types and there is no need to convert items.
  static List<T> toListPair<T>(dynamic value, {PairConverter<T> converter, bool hardCast: true}) {
    final items = List<T>();

    if (converter == null) {
      return toList<T>(value, hardCast: hardCast);
    }

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      value = value.toList().asMap();
    }

    if (value is Map) {
      value.forEach((key, item) {
        final listItem = converter(key, item);

        if (listItem != null && listItem is T) {
          items.add(listItem);
        }
      });
    } else {
      if (converter == null) {
        if (value is T) {
          items.add(value);
        } else {
          final listItem = converter('0', value);

          if (listItem != null && listItem is T) {
            items.add(listItem);
          }
        }
      }
    }

    return items;
  }

  /// Tries to parse value into Map.
  ///
  /// List, Map, Iterable.
  ///
  /// Use [ValueConverter] to convert values into new List.
  /// Use [hardCast] if you are sure that [value] contains expected Types and there is no need to convert items.
  static Map<String, T> toMap<T>(dynamic value, {ValueConverter<T> converter, bool hardCast: true}) {
    final items = Map<String, T>();

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      value = value.toList().asMap();
    }

    if (value is Map) {
      if (converter == null) {
        if (hardCast) {
          return value.cast<String, T>();
        }

        value.forEach((key, item) {
          if (item is T) {
            items[key.toString()] = item;
          }
        });
      } else {
        value.forEach((key, item) {
          final mapItem = converter(item);

          if (mapItem != null && mapItem is T) {
            items[key.toString()] = mapItem;
          }
        });
      }
    } else {
      if (converter == null) {
        if (value is T) {
          items['0'] = value;
        } else {
          final listItem = converter(value);

          if (listItem != null && listItem is T) {
            items['0'] = value;
          }
        }
      }
    }

    return items;
  }

  /// Tries to parse value into Map.
  /// If converter is not specified [Parse.toMap] is used instead.
  ///
  /// List, Map, Iterable.
  ///
  /// Use [PairConverter] to convert values into new Map.
  /// Use [hardCast] if you are sure that [value] contains expected Types and there is no need to convert items.
  static Map<String, T> toMapPair<T>(dynamic value, {PairConverter<T> converter, bool hardCast: true}) {
    final items = Map<String, T>();

    if (converter == null) {
      return toMap<T>(value, hardCast: hardCast);
    }

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      value = value.toList().asMap();
    }

    if (value is Map) {
      value.forEach((key, item) {
        final mapItem = converter(key, item);

        if (mapItem != null && mapItem is T) {
          items[key.toString()] = mapItem;
        }
      });
    } else {
      if (converter == null) {
        if (value is T) {
          items['0'] = value;
        } else {
          final listItem = converter('0', value);

          if (listItem != null && listItem is T) {
            items['0'] = listItem;
          }
        }
      }
    }

    return items;
  }

  /// Tries to return item of given [key] or [Type].
  /// If none found, then [defaultValue] is returned.
  /// Currently supports [Parse.getArgFromMap], [Parse.getArgFromList] and [Parse.getArgFromString]
  static T getArg<T>(dynamic value, {dynamic key, bool Function(dynamic) predicate, T defaultValue}) {
    if (value is Map) {
      return getArgFromMap<T>(value, key: key, predicate: predicate, defaultValue: defaultValue);
    }

    if (value is Iterable) {
      return getArgFromList<T>(value, predicate: predicate, defaultValue: defaultValue);
    }

    if (value is String) {
      return getArgFromString<T>(value, key: key, predicate: predicate, defaultValue: defaultValue);
    }

    return defaultValue;
  }

  /// Tries to return item of given [key], [Type] or [predicate].
  /// If [key] is not specified, then [Parse.getArgFromList] is used.
  /// If none found, then [defaultValue] is returned.
  static T getArgFromMap<T>(Map map, {dynamic key, bool Function(dynamic) predicate, T defaultValue}) {
    if (map == null) {
      return defaultValue;
    }

    if (key != null) {
      if (map.containsKey(key)) {
        return map[key];
      }

      if (key is Type) {
        final item = map.values.firstWhere((item) => item.runtimeType == key, orElse: () => null);

        if (item != null) {
          return item;
        }
      }
    }

    return getArgFromList(map.values, predicate: predicate, defaultValue: defaultValue);
  }

  /// Tries to return object of given [Type] or [predicate].
  /// If none found, then [defaultValue] is returned.
  static T getArgFromList<T>(Iterable iterable, {bool Function(dynamic) predicate, T defaultValue}) {
    if (iterable == null) {
      return defaultValue;
    }

    if (predicate != null) {
      final testItem = iterable.firstWhere(predicate, orElse: () => null);

      if (testItem != null) {
        return testItem;
      }
    }

    final typeItem = iterable.firstWhere((item) => item is T, orElse: () => null);

    if (typeItem != null) {
      return typeItem;
    }

    return defaultValue;
  }

  /// Converts input [value] to json, then tries to return object of given [key], [Type] or [predicate].
  /// If none found, then [defaultValue] is returned.
  static T getArgFromString<T>(String value, {dynamic key, bool Function(dynamic) predicate, T defaultValue}) {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    final json = jsonDecode(value);

    if (json is Map) {
      return getArgFromMap<T>(json, key: key, predicate: predicate, defaultValue: defaultValue);
    }

    if (json is Iterable) {
      return getArgFromList<T>(json, predicate: predicate, defaultValue: defaultValue);
    }

    return defaultValue;
  }
}
/*
extension ObjectExtension on String {
  T getArg<T>({dynamic key, bool Function(dynamic) predicate, T defaultValue}) => Parse.getArgFromString<T>(this, key: key, predicate: predicate, defaultValue: defaultValue);
}

extension MapExtension on Map {
  T getArg<T>({dynamic key, bool Function(dynamic) predicate, T defaultValue}) => Parse.getArgFromMap<T>(this, key: key, predicate: predicate, defaultValue: defaultValue);
}

extension IterableExtension on List {
  T getArg<T>({bool Function(dynamic) predicate, T defaultValue}) => Parse.getArgFromList<T>(this, predicate: predicate, defaultValue: defaultValue);
}
*/