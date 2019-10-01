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
    }

    return items;
  }

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
    }

    return items;
  }

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
    }

    return items;
  }

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
    }

    return items;
  }

  /// Tries to return item of given [key] or [Type].
  /// If none found, then [defaultValue] is returned.
  /// Currently supports [Parse.getArgFromMap], [Parse.getArgFromList] and [Parse.getArgFromString]
  static T getArg<T>(dynamic value, {dynamic key, T defaultValue}) {
    if (value is Map) {
      return getArgFromMap<T>(value, key: key, defaultValue: defaultValue);
    }

    if (value is Iterable) {
      return getArgFromList<T>(value, defaultValue: defaultValue);
    }

    if (value is String) {
      return getArgFromString<T>(value, key: key, defaultValue: defaultValue);
    }

    return defaultValue;
  }

  /// Tries to return item of given [key] or [Type].
  /// If none found, then [defaultValue] is returned.
  static T getArgFromMap<T>(Map map, {dynamic key, T defaultValue}) {
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

    final item = map.values.firstWhere((item) => item is T, orElse: () => null);

    if (item != null) {
      return item;
    }

    return defaultValue;
  }

  /// Tries to return object of given [Type].
  /// If none found, then [defaultValue] is returned.
  static T getArgFromList<T>(Iterable iterable, {T defaultValue}) {
    if (iterable == null) {
      return defaultValue;
    }

    final item = iterable.firstWhere((item) => item is T, orElse: () => null);

    if (item != null) {
      return item;
    }

    return defaultValue;
  }

  /// Converts input [value] to json, then tries to return object of given [key] or [Type].
  /// If none found, then [defaultValue] is returned.
  static T getArgFromString<T>(String value, {dynamic key, T defaultValue}) {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    final json = jsonDecode(value);

    if (json is Map) {
      return getArgFromMap<T>(json, key: key, defaultValue: defaultValue);
    }

    if (json is Iterable) {
      return getArgFromList<T>(json, defaultValue: defaultValue);
    }

    return defaultValue;
  }
}

/// Helps to look up for object in [Map] and [List].
/// deprecated now - user [Parse.getArg]
@deprecated
class ArgHandler {
  /// Tries to return item of given key or Type.
  /// If none found, then [defaultValue] is returned.
  /// deprecated now - user [Parse.getArg] or [Parse.getArgFromMap]
  @deprecated
  static T map<T>(Map map, {dynamic key, T defaultValue}) {
    if (map == null) {
      return defaultValue;
    }

    if (map.containsKey(key)) {
      return map[key];
    }

    final item = map.values.firstWhere((item) => item is T, orElse: () => null);

    if (item != null) {
      return item;
    }

    return defaultValue;
  }

  /// Tries to return object of given Type.
  /// If none found, then [defaultValue] is returned.
  /// deprecated now - user [Parse.getArg] or [Parse.getArgFromList]
  @deprecated
  static T list<T>(List list, {T defaultValue}) {
    if (list == null) {
      return defaultValue;
    }

    final item = list.firstWhere((item) => item is T, orElse: () => null);

    if (item != null) {
      return item;
    }

    return defaultValue;
  }

  /// Tries to return object of given Type.
  /// If none found, then [defaultValue] is returned.
  /// deprecated now - user [Parse.getArg] or [Parse.getArgFromList]
  @deprecated
  static T iterable<T>(Iterable iterable, {T defaultValue}) {
    if (iterable == null) {
      return defaultValue;
    }

    final item = iterable.firstWhere((item) => item is T, orElse: () => null);

    if (item != null) {
      return item;
    }

    return defaultValue;
  }
}
