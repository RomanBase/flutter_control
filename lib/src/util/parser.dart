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
  /// Use [Converter] to convert values into new List.
  static List<T> toList<T>(dynamic value, {Converter<T> converter, bool hardCast: true}) {
    final items = List<T>();

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      if (value is Map) {
        value = value.values;
      }

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
}

/// Helps to look up for object in [Map] and [List].
class ArgHandler {
  /// Tries to return item of given key or Type.
  /// If none found, then [defaultValue] is returned.
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
