part of control_core;

/// Stores data as arguments based on [key] - [value] pairs.
class ControlArgs implements Disposable {
  /// Map of stored data.
  final Map _args;

  /// Returns currently stored data.
  /// Mostly used by framework. Do not modify this data directly !
  /// Consider using [ControlArgs.set], [ControlArgs.get], [ControlArgs.add] functions or [] operators.
  Map get data => _args;

  const ControlArgs(this._args);

  factory ControlArgs.of([dynamic args]) => ControlArgs({})..set(args);

  static Map build(dynamic args) => (ControlArgs({})..set(args)).data;

  /// Returns object of given [key] or null.
  dynamic operator [](dynamic key) => _args.getArg(key: key);

  /// Sets [value] directly to store with given [key].
  /// Consider using [ControlArgs.set] or [ControlArgs.add] to prevent use of misleading [key].
  void operator []=(dynamic key, dynamic value) => _args[key] = value;

  /// Parses input data and stores them as key: value pair.
  /// Can store any type of data - Map, Iterable, Objects and more..
  /// [Map] - is directly added to data store.
  /// [Iterable] - is parsed and data are stored under their [Type].
  /// [Object] - is stored under his [Type].
  /// Other [ControlArgs] is combined.
  void set(dynamic args) {
    if (args == null) {
      return;
    }

    if (args is ControlArgs) {
      combine(args);
    } else if (args is Map) {
      _args.addAll(args);
    } else if (args is Set) {
      args.forEach((item) {
        _args[item.runtimeType] = item;
      });
    } else if (args is Iterable) {
      if (args.length > 1 &&
          args.every(
              (element) => element.runtimeType == args.first.runtimeType)) {
        _args[args.runtimeType] = args;
      } else {
        args.forEach((item) {
          _args[item.runtimeType] = item;
        });
      }
    } else {
      _args[args.runtimeType] = args;
    }
  }

  /// Adds [value] to data store under given [key].
  /// [ControlFactory.keyOf] is used to determine store key.
  void add<T>({dynamic key, required dynamic value}) =>
      _args[Control.factory.keyOf<T>(key: key, value: value)] = value;

  /// Combines this store with given [args].
  void combine(ControlArgs args) {
    _args.addAll(args._args);
  }

  /// Combines this store with given [args].
  /// Returns new [ControlArgs] that contains both [args].
  ControlArgs merge(ControlArgs args) {
    final store = ControlArgs.of(this);
    store._args.addAll(args._args);

    return store;
  }

  /// Whether this args contains the given [key].
  bool containsKey(dynamic key) => _args.containsKey(key);

  /// Returns object of given [key] or [defaultValue].
  T? get<T>({dynamic key, T? defaultValue}) =>
      Parse.getArgFromMap<T>(_args, key: key, defaultValue: defaultValue);

  /// Returns object of given [key] or initialize [defaultValue] and stores that value to args store.
  T? getWithFactory<T>({dynamic key, T Function()? defaultValue}) {
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
