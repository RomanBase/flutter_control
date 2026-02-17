part of '../../core.dart';

typedef ParseDecoratorFormat = String Function(String input);

/// A collection of decorators for string formatting with [Parse.format].
class ParseDecorator {
  const ParseDecorator._();

  /// An empty decorator that returns the input unchanged. 'input' => 'input'
  static ParseDecoratorFormat get none => (input) => input;

  /// A decorator that wraps the input in curly braces. 'input' => '{input}'
  static ParseDecoratorFormat get curl => (input) => '{$input}';

  /// A decorator that prepends a dollar sign. 'input' => '$input'
  static ParseDecoratorFormat get dollar => (input) => '\$$input';

  /// A decorator that prepends a percent sign. 'input' => '%input'
  static ParseDecoratorFormat get percent => (input) => '%$input';
}

/// A utility class with static methods for parsing data types that can explicitly return `null`.
///
/// This is in contrast to the main [Parse] class, where methods typically return a
/// non-nullable default value on failure.
class ParseN {
  const ParseN._();

  /// Tries to parse a value into a [String]. Returns `null` on failure.
  static String? string(dynamic value) {
    if (value is String) {
      return value;
    }

    if (value != null) {
      return value.toString();
    }

    return null;
  }

  /// Tries to parse a value into an [int]. Returns `null` on failure.
  /// Handles `int`, `double`, `bool`, and `String` inputs.
  static int? toInteger(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value == null) {
      return null;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is bool) {
      return value ? 1 : 0;
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }

    return null;
  }

  /// Tries to parse a value into a [double]. Returns `null` on failure.
  /// Handles `int`, `double`, `bool`, and `String` inputs.
  static double? toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is bool) {
      return value ? 1.0 : 0.0;
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }

    return null;
  }

  /// Tries to parse a value into a [bool]. Returns `null` on failure.
  /// Handles `int`, `double`, `bool`, and `String` inputs.
  static bool? toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value == null) {
      return null;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    final num = toInteger(value);

    if (num != null) {
      return num > 0;
    }

    return null;
  }
}

/// A utility class with static methods for robust data parsing and type conversion.
class Parse {
  const Parse._();

  /// Formats a string by replacing placeholders with values from a map.
  ///
  /// Placeholders in the [input] string are identified by the [decorator].
  /// The default decorator is [ParseDecorator.curl], which looks for `{key}`.
  ///
  /// Example:
  /// ```dart
  /// Parse.format('Hello, {name}!', {'name': 'World'}); // "Hello, World!"
  /// ```
  static String format(String input, Map<String, String> params,
      [ParseDecoratorFormat? decorator]) {
    decorator ??= ParseDecorator.curl;

    params.forEach(
        (key, value) => input = input.replaceFirst(decorator!(key), value));

    return input;
  }

  /// Tries to parse a dynamic value into a [DateTime].
  ///
  /// Supports numbers (timestamps in milliseconds or seconds) and ISO 8601 strings.
  static DateTime? date(dynamic value, {bool inSec = false}) {
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

  /// Tries to parse a dynamic value into a [String].
  /// Returns [defaultValue] if parsing fails or the value is null.
  static String string(dynamic value, {String defaultValue = ''}) {
    if (value is String) {
      return value;
    }

    if (value != null) {
      return value.toString();
    }

    return defaultValue;
  }

  /// Tries to parse a dynamic value into an [int].
  /// Returns [defaultValue] if parsing fails.
  static int toInteger(dynamic value, {int defaultValue = 0}) {
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

  /// Tries to parse a dynamic value into a [double].
  /// Returns [defaultValue] if parsing fails.
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
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
      return double.tryParse(value.replaceAll(',', '.')) ?? defaultValue;
    }

    return defaultValue;
  }

  /// Tries to parse a dynamic value into a [bool].
  /// Returns [defaultValue] if parsing fails.
  static bool toBool(dynamic value, {bool defaultValue = false}) {
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

  /// Parses a string representation of an enum into its corresponding enum value.
  /// The comparison is case-insensitive.
  /// Returns [defaultValue] or the first enum value if parsing fails.
  static T toEnum<T>(dynamic value, List<T> enums, {T? defaultValue}) {
    if (value == null) {
      return defaultValue ?? enums[0];
    }

    final name = string(value).toLowerCase();

    return enums.firstWhere((item) => fromEnum(item)!.toLowerCase() == name,
        orElse: () => defaultValue ?? enums[0]);
  }

  /// Returns the string name of an enum value (e.g., `MyEnum.value` => `"value"`).
  /// Returns `null` if the input is not a valid enum.
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

  /// Safely converts a dynamic value to type [T] using a [converter] function.
  /// Returns [defaultValue] if the conversion throws an error.
  static T? convert<T>(dynamic value,
      {required ValueConverter<T> converter, T? defaultValue}) {
    try {
      return converter(value) ?? defaultValue;
    } catch (err) {
      printDebug('failed to convert $T from ${value?.toString()}');
    }

    return defaultValue;
  }

  /// Safely converts a key-value pair to type [T] using an [entryConverter] function.
  /// Returns [defaultValue] if the conversion throws an error.
  static T? convertEntry<T>(dynamic key, dynamic value,
      {required EntryConverter<T> converter, T? defaultValue}) {
    try {
      return converter(key, value) ?? defaultValue;
    } catch (err) {
      printDebug(
          'failed to convert $T from ${key?.toString()} : ${value?.toString()}');
    }

    return defaultValue;
  }

  /// Converts a dynamic value to a descriptive string name.
  /// Handles primitives, enums, and types.
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

  /// Returns the [Type] from a generic argument `T` or a dynamic `value`.
  /// Defaults to `dynamic` if type information is unavailable.
  static Type type<T>([dynamic value]) =>
      T != dynamic ? T : (value?.runtimeType ?? dynamic);

  /// Returns `true` if the generic type `T` is nullable.
  static bool nullableType<T>() => null is T || T == dynamic;

  /// Tries to parse a dynamic value into a `List<T>`.
  ///
  /// Supports `List`, `Map` (uses values), and other `Iterable`s.
  /// - [converter]/[entryConverter]: Functions to convert each item to type `T`.
  /// - [hardCast]: If `true`, attempts a direct `cast<T>()`, which is faster but can fail at runtime.
  static List<T> toList<T>(dynamic value,
      {ValueConverter<T>? converter, EntryConverter<T>? entryConverter}) {
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
        for (final item in value) {
          final listItem = convert(item, converter: converter);

          if (listItem != null) {
            items.add(listItem);
          }
        }
      } else if (entryConverter != null) {
        valueMap ??= value.toList().asMap();

        valueMap.forEach((key, item) {
          final listItem = convertEntry(key, item, converter: entryConverter);

          if (listItem != null) {
            items.add(listItem);
          }
        });
      } else {
        return List.of(value.cast());
      }
    } else {
      if (converter != null) {
        final listItem = convert(value, converter: converter);

        if (listItem != null) {
          items.add(listItem);
        }
      } else if (entryConverter != null) {
        final listItem = convertEntry(0, value, converter: entryConverter);

        if (listItem != null) {
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

  /// Tries to parse a dynamic value into a `Map<K, T>`.
  ///
  /// Supports `List`, `Map`, and other `Iterable`s.
  /// - [key]: A function to convert a source key into the target key of type `K`.
  /// - [converter]/[entryConverter]: Functions to convert each value to type `T`.
  static Map<K, T> toMap<K, T>(dynamic value,
      {EntryConverter<K>? key,
      ValueConverter<T>? converter,
      EntryConverter<T>? entryConverter}) {
    final items = <K, T>{};

    if (value == null) {
      return items;
    }

    if (value is Iterable) {
      value = value.toList().asMap();
    }

    final keyConverter = key ?? (key, _) => key as K;

    if (value is Map) {
      if (converter != null) {
        value.forEach((key, item) {
          final mapItem = convert(item, converter: converter);

          if (mapItem != null) {
            items[keyConverter(key, item)] = mapItem;
          }
        });
      } else if (entryConverter != null) {
        value.forEach((key, item) {
          final mapItem = convertEntry(key, item, converter: entryConverter);

          if (mapItem != null) {
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

        if (listItem != null) {
          items[keyConverter(0, listItem)] = listItem;
        }
      } else if (entryConverter != null) {
        final listItem = convertEntry(0, value, converter: entryConverter);

        if (listItem != null) {
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

  /// Dynamically retrieves an argument from a nested data structure (`Map`, `Iterable`, `ControlArgs`).
  ///
  /// This is a powerful utility for extracting a value without knowing the exact
  /// structure of the source data.
  ///
  /// - [value]: The source data structure.
  /// - [key]: An optional key to look for in a `Map`.
  /// - [predicate]: An optional test to find an item in an `Iterable`.
  /// - [defaultValue]: A fallback value if nothing is found.
  static T? getArg<T>(dynamic value,
      {dynamic key, bool Function(dynamic)? predicate, T? defaultValue}) {
    if (value is T && T != dynamic) {
      return value;
    }

    if (value is ControlArgs) {
      return value.get<T>(key: key, defaultValue: defaultValue);
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
      try {
        return getArg<T>(jsonDecode(value),
            key: key, predicate: predicate, defaultValue: defaultValue);
      } catch (err) {
        printDebug(err);
      }
    }

    return defaultValue;
  }

  /// Tries to return an item from a map by [key], [Type], or [predicate].
  ///
  /// If [key] is not specified, it falls back to searching the map's values.
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

  /// Tries to return an item from an iterable by [Type] or [predicate].
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

  /// Creates a copy of a map, filtering out null keys, null values, and empty iterables/strings.
  static Map<K, V> fill<K, V>(Map<K, V> map) => Map.from(map)
    ..removeWhere((key, value) =>
        key == null ||
        value == null ||
        (value is Iterable && value.isEmpty) ||
        (value is String && value.isEmpty));
}

extension MapExtension on Map {
  /// An extension method equivalent to [Parse.getArgFromMap].
  T? getArg<T>(
          {dynamic key,
          bool Function(dynamic)? predicate,
          T? defaultValue,
          T? Function()? builder}) =>
      Parse.getArgFromMap<T>(this,
          key: key, predicate: predicate, defaultValue: defaultValue) ??
      builder?.call();

  /// An extension method equivalent to [Parse.fill].
  Map<K, V> fill<K, V>() => Parse.fill(this) as Map<K, V>;
}

extension ListExt<E> on List<E> {
  void swapByIndex(int a, int b) {
    if (a > b) {
      final c = a;
      a = b;
      b = c;
    }

    final itemA = this[a];
    final itemB = this[b];

    removeAt(b);
    removeAt(a);

    insert(a, itemB);
    insert(b, itemA);
  }

  void reorder(int oldIndex, int newIndex) {
    final element = removeAt(oldIndex);

    if (oldIndex > newIndex) {
      insert(newIndex, element);
    } else {
      insert(newIndex - 1, element);
    }
  }

  List<T> iterate<T>(T Function(int index, E e) toElement,
          [bool growable = false]) =>
      List.generate(length, (index) => toElement(index, this[index]),
          growable: growable);

  List<T> iterateReversed<T>(T Function(int index, int rIndex, E e) toElement,
          [bool growable = false]) =>
      List.generate(length, (index) {
        final rIndex = length - index - 1;
        return toElement(index, rIndex, this[rIndex]);
      }, growable: growable);

  List<List<E>?> foldBy(int count) {
    final list = <List<E>?>[];

    if (length <= count) {
      list.add(this);
    } else {
      List<E>? current;

      for (int i = 0; i < length; i++) {
        if (i % count == 0) {
          current = <E>[];
          list.add(current);
        }

        current!.add(this[i]);
      }
    }

    return list;
  }
}

extension IterableExtension on Iterable {
  /// Casts an iterable to be nullable.
  Iterable<T?> nullable<T>() => cast<T?>();

  /// An extension method equivalent to [Parse.getArgFromList].
  T? getArg<T>(
          {bool Function(dynamic)? predicate,
          T? defaultValue,
          T? Function()? builder}) =>
      Parse.getArgFromList<T>(this,
          predicate: predicate, defaultValue: defaultValue) ??
      builder?.call();

  List<T> insertEvery<T>(T Function(T item) builder, {T? header, T? footer}) {
    final list = expand((item) sync* {
      final newItem = builder(item);

      if (newItem != null) {
        yield newItem;
      }

      yield item;
    }).skip(1).toList().cast<T>();

    if (header != null) {
      list.insert(0, header);
    }

    if (footer != null) {
      list.add(footer);
    }

    return list;
  }

  T? find<T>(bool Function(T element) test, {T Function()? orElse}) {
    for (T element in this) {
      if (test(element)) return element;
    }

    if (orElse != null) return orElse();

    return null;
  }
}
