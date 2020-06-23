import 'package:flutter_control/core.dart';

/// Stores data as arguments based on [key] - [value] pairs.
class ControlArgs implements Disposable {
  /// Map of stored data.
  final _args = Map();

  /// Returns currently stored data.
  /// Mostly used by framework. Do not modify this data directly !
  /// Consider using [ControlArgs.set], [ControlArgs.get], [ControlArgs.add] functions or [] operators.
  Map get data => _args;

  /// Stores data as arguments.
  /// Can store any type of data - [Map], [Iterable], [Object]..
  /// [ControlArgs.set] parses input data and stores them as key: value pair.
  ControlArgs([dynamic args]) {
    set(args);
  }

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
    } else if (args is Iterable) {
      args.forEach((item) {
        _args[item.runtimeType] = item;
      });
    } else {
      _args[args.runtimeType] = args;
    }
  }

  /// Adds [value] to data store under given [key].
  /// [ControlFactory.keyOf] is used to determine store key.
  void add<T>({dynamic key, @required dynamic value}) => _args[Control.factory().keyOf<T>(key: key, value: value)] = value;

  /// Clears original data and stores items from [args].
  void swap(ControlArgs args) {
    assert(args != null);

    _args.clear();
    _args.addAll(args._args);
  }

  /// Combines this store with given [args].
  void combine(ControlArgs args) {
    assert(args != null);

    _args.addAll(args._args);
  }

  //TODO: purpose ?
  /// Ensures that data store contains given [key]. Otherwise [value] is stored under given [key].
  bool ensureArg(dynamic key, dynamic value) {
    if (key == null || value == null) {
      return false;
    }

    if (this[key] == null) {
      this[key] = value;
    }

    return true;
  }

  /// Returns object of given [key] or [defaultValue].
  T get<T>({dynamic key, T defaultValue}) => Parse.getArgFromMap<T>(_args, key: key, defaultValue: defaultValue);

  /// Returns all items for given [test].
  List<T> getAll<T>({Predicate test}) {
    if (test == null && T != dynamic) {
      test = (item) => item is T;
    }

    final list = _args.values.where(test).toList();

    if (T != dynamic) {
      return list.cast<T>();
    }

    return list;
  }

  /// Removes item by [Type] or [key].
  void remove<T>({dynamic key}) => _args.remove(key ?? T);

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
