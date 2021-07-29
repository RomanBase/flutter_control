import 'dart:convert';

import 'package:flutter_control/core.dart';

typedef ParamDecoratorFormat = String Function(String input);

/// Base param decorators for [Parse.format].
class ParamDecorator {
  /// Empty decorator. 'input' => 'input'
  static ParamDecoratorFormat get none => (input) => input;

  /// Curl braces decorator. 'input' => '{input}'
  static ParamDecoratorFormat get curl => (input) => '\{$input\}';

  /// Dollar sign decorator. 'input' => '$input'
  static ParamDecoratorFormat get dollar => (input) => '\$$input';

  /// Percent sign decorator. 'input' => '%input'
  static ParamDecoratorFormat get percent => (input) => '\%$input';
}

/// Helps to parse basic objects.
class Parse {
  /// Replaces [params] in [input] string
  /// Simply replaces strings with params. For more complex formatting can be better to use [Intl].
  /// Set custom [ParamDecoratorFormat] to decorate param, for example: 'city' => '{city}' or 'city' => '$city'
  ///
  /// Default decorator is set to [ParamDecorator.curl]
  ///
  /// 'Weather in {city} is {temp}°{symbol}'
  /// Then [params] are:
  /// {
  /// {'city': 'California'},
  /// {'temp': '25.5'},
  /// {'symbol': 'C'},
  /// }
  ///
  /// Returns formatted string.
  static String format(String input, Map<String, String> params,
      [ParamDecoratorFormat? decorator]) {
    decorator ??= ParamDecorator.curl;

    params.forEach(
        (key, value) => input = input.replaceFirst(decorator!(key), value));

    return input;
  }

  /// Tries to parse [value] int [DateTime]
  ///
  /// [num] - milliseconds or seconds - [isSec] `true`
  /// [String] - ISO formatted date and time.
  /// Timestamp or any other object with `toDate` method.
  static DateTime? toDate(dynamic value, {bool inSec: false}) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
          inSec ? value * 1000 as int : value as int);
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      return value.toDate();
    } on NoSuchMethodError {
      return null;
    }
  }

  /// Tries to parse value into [String].
  ///
  /// If none found, then [defaultValue] is returned.
  static String string(dynamic value, {String defaultValue: ''}) {
    if (value is String) {
      return value;
    }

    if (value != null) {
      return value.toString();
    }

    return defaultValue;
  }

  /// Tries to parse value into [integer].
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
      return int.tryParse(value) ??
          double.tryParse(value)?.toInt() ??
          defaultValue;
    }

    return defaultValue;
  }

  /// Tries to parse value into [double].
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

  /// Tries to parse value into [bool].
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

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    final num = toInteger(value, defaultValue: -1);

    if (num > -1) {
      return num > 0;
    }

    return defaultValue;
  }

  /// Parse input [value] to String and then to enum. Parsing is case insensitive.
  /// If enum of given name is not found, [defaultValue] or first value from [enums] is returned.
  static T toEnum<T>(dynamic value, List<T> enums, {T? defaultValue}) {
    if (value == null) {
      return defaultValue ?? enums[0];
    }

    final name = string(value).toLowerCase();

    return enums.firstWhere((item) => fromEnum(item)!.toLowerCase() == name,
        orElse: () => defaultValue ?? enums[0]);
  }

  /// Returns name of given enum [value].
  /// If given [value] is empty or not enum, null is returned.
  static String? fromEnum(dynamic value) {
    if (value == null) {
      return null;
    }

    final data = value.toString().split('.');

    if (data.length == 2) {
      return data[1];
    }

    return null;
  }

  /// Safety converts value to give [Type]
  /// If conversion fails, then is [defaultValue] returned.
  static T? convert<T>(dynamic value,
      {required ValueConverter<T> converter, T? defaultValue}) {
    try {
      return converter(value) ?? defaultValue;
    } catch (err) {
      printDebug(
          'failed to convert ${value?.toString()} to ${T.runtimeType.toString()}');
    }

    return defaultValue;
  }

  /// Safety converts value to give [Type]
  /// If conversion fails, then is [defaultValue] returned.
  static T? convertEntry<T>(dynamic key, dynamic value,
      {required EntryConverter<T> converter, T? defaultValue}) {
    try {
      return converter(key, value) ?? defaultValue;
    } catch (err) {
      printDebug(
          'failed to convert ${key?.toString()} : ${value?.toString()} to ${T.runtimeType.toString()}');
    }

    return defaultValue;
  }

  /// Converts given [value] to String - input [value] name is parsed based on [Type].
  /// Primitives are just converted to [String].
  /// For [Enum] value name is parsed.
  /// Otherwise [Type] name is returned.
  static String name(dynamic value) {
    if (value == null) {
      return 'none';
    }

    if (value is num) {
      return value.toString();
    }

    if (value is bool) {
      return value.toString();
    }

    if (value is Type) {
      return value.toString();
    }

    final enumValue = fromEnum(value);

    if (enumValue != null) {
      return enumValue;
    }

    if (value is String) {
      return value;
    }

    return value.runtimeType.toString();
  }

  /// Returns [Type] from given [T] or [value].
  /// Returns `dynamic` if [T] is not passed and [value] is `null`.
  static Type type<T>([dynamic value]) =>
      T != dynamic ? T : (value?.runtimeType ?? dynamic);

  /// Tries to parse value into List.
  ///
  /// List, Map, Iterable.
  ///
  /// Use [converter] or [entryConverter] to convert values into new List.
  /// Use [hardCast] if you are sure that [value] contains expected Types and there is no need to convert items.
  static List<T> toList<T>(dynamic value,
      {ValueConverter<T>? converter,
      EntryConverter<T>? entryConverter,
      bool hardCast: false}) {
    final items = <T>[];
    Map? valueMap;

    if (value == null) {
      return items;
    }

    if (value is Map) {
      valueMap = value;
      value = value.values;
    }

    if (value is Iterable) {
      if (converter != null) {
        value.forEach((item) {
          final listItem = convert(item, converter: converter);

          if (listItem != null && listItem is T) {
            items.add(listItem);
          }
        });
      } else if (entryConverter != null) {
        if (valueMap == null) {
          valueMap = value.toList().asMap();
        }

        valueMap.forEach((key, item) {
          final listItem = convertEntry(key, item, converter: entryConverter);

          if (listItem != null && listItem is T) {
            items.add(listItem);
          }
        });
      } else {
        if (value is List && hardCast) {
          try {
            return value.cast<T>();
          } catch (err) {
            printDebug(err.toString());
          }
        }

        value.forEach((item) {
          if (item is T) {
            items.add(item);
          }
        });
      }
    } else {
      if (converter != null) {
        final listItem = convert(value, converter: converter);

        if (listItem != null && listItem is T) {
          items.add(listItem);
        }
      } else if (entryConverter != null) {
        final listItem = convertEntry(0, value, converter: entryConverter);

        if (listItem != null && listItem is T) {
          items.add(listItem);
        }
      } else {
        if (value is T) {
          items.add(value);
        }
      }
    }

    return items;
  }

  /// Tries to parse value into Map.
  ///
  /// List, Map, Iterable.
  ///
  /// Use [converter] or [entryConverter] to convert values.
  /// Use [hardCast] if you are sure that [value] contains expected Types and there is no need to convert items.
  static Map<dynamic, T> toMap<T>(dynamic value,
      {ValueConverter<T>? converter,
      EntryConverter<T>? entryConverter,
      bool hardCast: false}) {
    final items = Map<dynamic, T>();

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      value = value.toList().asMap();
    }

    if (value is Map) {
      if (converter != null) {
        value.forEach((key, item) {
          final mapItem = convert(item, converter: converter);

          if (mapItem != null && mapItem is T) {
            items[key] = mapItem;
          }
        });
      } else if (entryConverter != null) {
        value.forEach((key, item) {
          final mapItem = convertEntry(key, item, converter: entryConverter);

          if (mapItem != null && mapItem is T) {
            items[key] = mapItem;
          }
        });
      } else {
        if (hardCast) {
          try {
            return value.cast<dynamic, T>();
          } catch (err) {
            printDebug(err.toString());
          }
        }

        value.forEach((key, item) {
          if (item is T) {
            items[key] = item;
          }
        });
      }
    } else {
      if (converter != null) {
        final listItem = convert(value, converter: converter);

        if (listItem != null && listItem is T) {
          items[0] = listItem;
        }
      } else if (entryConverter != null) {
        final listItem = convertEntry(0, value, converter: entryConverter);

        if (listItem != null && listItem is T) {
          items[0] = listItem;
        }
      } else {
        if (value is T) {
          items[0] = value;
        }
      }
    }

    return items;
  }

  /// Tries to parse value into Map.
  ///
  /// List, Map, Iterable.
  ///
  /// Use [converter] or [entryConverter] to convert value to [T]. [keyConverter] converts key to [K].
  /// Use [hardCast] if you are sure that [value] contains expected Types and there is no need to convert items.
  static Map<K, T> toKeyMap<K, T>(dynamic value, EntryConverter<K> keyConverter,
      {ValueConverter<T>? converter, EntryConverter<T>? entryConverter}) {
    final items = Map<K, T>();

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      value = value.toList().asMap();
    }

    if (value is Map) {
      if (converter != null) {
        value.forEach((key, item) {
          final mapItem = convert(item, converter: converter);

          if (mapItem != null && mapItem is T) {
            items[keyConverter(key, item)] = mapItem;
          }
        });
      } else if (entryConverter != null) {
        value.forEach((key, item) {
          final mapItem = convertEntry(key, item, converter: entryConverter);

          if (mapItem != null && mapItem is T) {
            items[keyConverter(key, item)] = mapItem;
          }
        });
      } else {
        value.forEach((key, item) {
          if (item is T) {
            items[keyConverter(key, item)] = item;
          }
        });
      }
    } else {
      if (converter != null) {
        final listItem = convert(value, converter: converter);

        if (listItem != null && listItem is T) {
          items[keyConverter(0, listItem)] = listItem;
        }
      } else if (entryConverter != null) {
        final listItem = convertEntry(0, value, converter: entryConverter);

        if (listItem != null && listItem is T) {
          items[keyConverter(0, listItem)] = listItem;
        }
      } else {
        if (value is T) {
          items[keyConverter(0, value)] = value;
        }
      }
    }

    return items;
  }

  /// Converts [value] and additional [data] into Map of arguments.
  /// Check [ControlArgs] for more info.
  static Map toArgs(dynamic value, {dynamic data}) {
    final buildArgs = ControlArgs(value);

    buildArgs.set(data);

    return buildArgs.data;
  }

  /// Tries to return item of given [key] or [Type].
  /// If none found, then [defaultValue] is returned.
  /// Currently supports [Parse.getArgFromMap], [Parse.getArgFromList] and [Parse.getArgFromString]
  static T? getArg<T>(dynamic value,
      {dynamic key, bool Function(dynamic)? predicate, T? defaultValue}) {
    if (value is T && T != dynamic) {
      return value;
    }

    if (value is Map) {
      return getArgFromMap<T>(value,
          key: key, predicate: predicate, defaultValue: defaultValue);
    }

    if (value is Iterable) {
      return getArgFromList<T>(value,
          predicate: predicate, defaultValue: defaultValue);
    }

    if (value is String) {
      return getArgFromString<T>(value,
          key: key, predicate: predicate, defaultValue: defaultValue);
    }

    return defaultValue;
  }

  /// Tries to return item of given [key], [Type] or [predicate].
  /// If [key] is not specified, then [Parse.getArgFromList] is used.
  /// If none found, then [defaultValue] is returned.
  static T? getArgFromMap<T>(Map? map,
      {dynamic key, bool Function(dynamic)? predicate, T? defaultValue}) {
    if (map == null) {
      return defaultValue;
    }

    if (key != null) {
      if (map.containsKey(key)) {
        return map[key];
      }

      if (key is Type) {
        final item = map.values
            .nullable()
            .firstWhere((item) => item.runtimeType == key, orElse: () => null);

        if (item != null) {
          return item;
        }
      }

      if (predicate == null) {
        return defaultValue;
      }
    }

    if (T != dynamic && predicate == null) {
      final item = map.values
          .nullable()
          .firstWhere((item) => item is T, orElse: () => null);

      if (item != null) {
        return item;
      }
    }

    return getArgFromList<T>(map.values,
        predicate: predicate, defaultValue: defaultValue);
  }

  /// Tries to return object of given [Type] or [predicate].
  /// If none found, then [defaultValue] is returned.
  static T? getArgFromList<T>(Iterable? iterable,
      {bool Function(dynamic)? predicate, T? defaultValue}) {
    if (iterable == null) {
      return defaultValue;
    }

    if (predicate != null) {
      final testItem =
          iterable.nullable().firstWhere(predicate, orElse: () => null);

      if (testItem != null) {
        return testItem;
      }
    } else {
      if (T != dynamic) {
        final typeItem = iterable
            .nullable()
            .firstWhere((item) => item is T, orElse: () => null);

        if (typeItem != null) {
          return typeItem;
        }
      }
    }

    return defaultValue;
  }

  /// Converts input [value] to json, then tries to return object of given [key], [Type] or [predicate].
  /// If none found, then [defaultValue] is returned.
  static T? getArgFromString<T>(String? value,
      {dynamic key, bool Function(dynamic)? predicate, T? defaultValue}) {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    final json = jsonDecode(value);

    if (json is Map) {
      return getArgFromMap<T>(json,
          key: key, predicate: predicate, defaultValue: defaultValue);
    }

    if (json is Iterable) {
      return getArgFromList<T>(json,
          predicate: predicate, defaultValue: defaultValue);
    }

    return defaultValue;
  }

  /// Creates copy of given [map] and filters out [null] values. Also empty [Iterable] or [String] is not included in returned [Map].
  static Map<K, V> fill<K, V>(Map<K, V> map) => Map.from(map)
    ..removeWhere((key, value) =>
        key == null ||
        value == null ||
        (value is Iterable && value.isEmpty) ||
        (value is String && value.isEmpty));
}

extension ObjectExtension on Object {
  ObjectTag asTag() => ObjectTag.of(hashCode);

  ControlArgs asArg() => ControlArgs(this);

  T? getArg<T>({dynamic key, T? defaultValue}) =>
      Parse.getArg<T>(this is ControlArgs ? (this as ControlArgs).data : this,
          key: key, defaultValue: defaultValue);
}

extension MapExtension on Map {
  /// [Parse.getArgFromMap].
  T? getArg<T>(
          {dynamic key, bool Function(dynamic)? predicate, T? defaultValue}) =>
      Parse.getArgFromMap<T>(this,
          key: key, predicate: predicate, defaultValue: defaultValue);

  /// [Parse.fill].
  Map<K, V?> fill<K, V>() => Parse.fill(this as Map<K, V?>);
}

extension IterableExtension on Iterable {
  Iterable<T?> nullable<T>() => cast<T?>();

  /// [Parse.getArgFromList].
  T? getArg<T>({bool Function(dynamic)? predicate, T? defaultValue}) =>
      Parse.getArgFromList<T>(this,
          predicate: predicate, defaultValue: defaultValue);

  List<T> insertEvery<T>(T Function(T item) builder, {T? header, T? footer}) {
    final list = this
        .expand((item) sync* {
          final newItem = builder(item);

          if (newItem != null) {
            yield newItem;
          }

          yield item;
        })
        .skip(1)
        .toList()
        .cast<T>();

    if (header != null) {
      list.insert(0, header);
    }

    if (footer != null) {
      list.add(footer);
    }

    return list;
  }

  Map toKeyMap() => Parse.toKeyMap(this, (key, value) => value.runtimeType);
}
