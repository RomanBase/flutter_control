part of '../../core.dart';

/// A flexible container for managing arguments passed between different parts of the application.
///
/// `ControlArgs` simplifies passing and retrieving data, especially during object
/// initialization via `ControlFactory`. It can parse various data structures like
/// `Map`, `Iterable`, or other `ControlArgs` into a unified key-value store.
///
/// Example:
/// ```dart
/// // Create args from a map and an object.
/// final args = ControlArgs.of({
///   'id': 123,
///   'user': User(name: 'Alex'),
/// });
///
/// // Retrieve values
/// final id = args.get<int>(key: 'id');
/// final user = args.get<User>(); // Retrieves by type
/// ```
class ControlArgs implements Disposable {
  /// Map of stored data.
  final Map _args;

  /// A read-only view of the underlying data map.
  ///
  /// To modify the data, use methods like [set], [add], or [combine].
  Map get data => _args;

  /// Stores data as arguments.
  /// Initial raw [args] - given [args] are not processed. Use [ControlArgs.of] factory to process given [args].
  /// Check [set] for more info.
  const ControlArgs(this._args);

  /// Stores data as arguments.
  /// Given [args] are processed and stored.
  /// Check [set] for more info.
  factory ControlArgs.of([dynamic args]) => ControlArgs({})..set(args);

  /// Process given [args] and return arguments as Map [data].
  static Map build(dynamic args) => (ControlArgs({})..set(args)).data;

  /// Returns object of given [key] or null.
  dynamic operator [](dynamic key) => _args.getArg(key: key);

  /// Sets [value] directly to store with given [key].
  /// Consider using [ControlArgs.set] or [ControlArgs.add] to prevent use of misleading [key].
  void operator []=(dynamic key, dynamic value) => _args[key] = value;

  /// Parses and adds dynamic data to the argument store.
  ///
  /// This method intelligently handles different data types:
  /// - `Map`: Merges the map's key-value pairs.
  /// - `ControlArgs`: Combines the data from the other `ControlArgs` instance.
  /// - `Iterable`: Adds each item, using its runtime type as the key. If all items
  ///   are of the same type, the whole iterable is stored as well.
  /// - Other `Object`: Stores the object using its runtime type as the key.
  void set(dynamic args) {
    if (args == null) {
      return;
    }

    if (args is ControlArgs) {
      combine(args);
    } else if (args is Map) {
      _args.addAll(args);
    } else if (args is Set) {
      for (final item in args) {
        _args[item.runtimeType] = item;
      }
    } else if (args is Iterable) {
      if (args.length > 1 &&
          args.every(
              (element) => element.runtimeType == args.first.runtimeType)) {
        _args[args.runtimeType] = args;
      } else {
        for (final item in args) {
          _args[item.runtimeType] = item;
        }
      }
    } else {
      _args[args.runtimeType] = args;
    }
  }

  /// Adds a [value] to the store with an optional [key].
  ///
  /// If [key] is not provided, it is inferred from the type `T` or the value's runtime type.
  void add<T>({dynamic key, required dynamic value}) =>
      _args[Control.factory.keyOf<T>(key: key, value: value)] = value;

  /// Merges the data from another [ControlArgs] instance into this one.
  void combine(ControlArgs args) {
    _args.addAll(args._args);
  }

  /// Combines this store with given [args].
  /// Returns new [ControlArgs] that contains [data] of both instances.
  ControlArgs merge(ControlArgs args) {
    final store = ControlArgs.of(this);
    store._args.addAll(args._args);

    return store;
  }

  /// Whether this args contains the given [key].
  bool containsKey(dynamic key) => _args.containsKey(key);

  /// Retrieves a value of type [T] from the store.
  ///
  /// Lookup is performed by [key] if provided, otherwise by type [T].
  /// Returns [defaultValue] if no matching value is found.
  T? get<T>({dynamic key, T? defaultValue}) =>
      Parse.getArgFromMap<T>(_args, key: key, defaultValue: defaultValue);

  /// Retrieves a value, or creates and stores a default value if not found.
  ///
  /// A "get-or-create" utility. If a value for the given [key] or type is not
  /// found, the [defaultValue] function is called, and its result is stored
  /// before being returned.
  T? use<T>({dynamic key, T Function()? defaultValue}) {
    final item = Parse.getArgFromMap<T>(_args, key: key);

    if (item == null && defaultValue != null) {
      final defaultItem = defaultValue.call();
      add<T>(key: key, value: defaultItem);

      return defaultItem;
    }

    return item;
  }

  /// Returns all items for given [test].
  List<T> getAll<T>({Predicate? test}) {
    assert(test != null || T != dynamic);

    if (test == null && T != dynamic) {
      test = (item) => item is T;
    }

    final list = _args.values.where(test!).toList();

    if (T != dynamic) {
      return list.cast<T>();
    }

    return list as List<T>;
  }

  /// Removes all items for given [test].
  void removeAll<T>({Predicate? test}) {
    if (test == null && T != dynamic) {
      test = (item) => item is T;
    } else {
      clear();
      return;
    }

    _args.removeWhere((key, value) => test!(value));
  }

  /// Removes item by [Type] or [key].
  T? remove<T>({dynamic key}) {
    assert(key != null || T != dynamic);

    return _args.remove(Control.factory.keyOf<T>(key: key));
  }

  /// Removes and returns item by [Type] or [key].
  T? pop<T>({dynamic key}) {
    assert(key != null || T != dynamic);

    final value = get<T>(key: key);

    if (value != null) {
      remove<T>(key: key);
    }

    return value;
  }

  /// Clears whole data store.
  void clear() => _args.clear();

  @override
  void dispose() {
    _args.clear();
  }

  void printDebugStore() {
    printDebug('--- Args ---');
    _args.forEach((key, value) {
      printDebug('$key: $value');
    });
    printDebug('------------');
  }

  @override
  String toString() {
    return 'ControlArgs.$hashCode - [${_args.length}]';
  }
}
