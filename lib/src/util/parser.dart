import 'package:flutter_control/core.dart';

class Parse {
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

  static List<T> toList<T>(dynamic value, {Converter<T> converter}) {
    final items = List<T>();

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      if (value is Map) {
        value = value.values;
      }

      if (converter == null) {
        value.forEach((item) => items.add(item));
      } else {
        value.forEach((item) => items.add(converter(item)));
      }
    }

    return items;
  }
}
