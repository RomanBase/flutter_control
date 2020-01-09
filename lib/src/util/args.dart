import 'package:flutter_control/core.dart';

class ControlArgs implements Disposable {
  final _args = Map();

  Map get data => _args;

  ControlArgs([dynamic args]) {
    set(args);
  }

  dynamic operator [](dynamic key) => _args.getArg(key: key);

  void operator []=(dynamic key, dynamic value) => _args[key] = value;

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

  void swap(ControlArgs args) {
    assert(args != null);

    _args.clear();
    _args.addAll(args._args);
  }

  void combine(ControlArgs args) {
    assert(args != null);

    _args.addAll(args._args);
  }

  void ensureArg(dynamic key, dynamic value) {
    assert(key != null);
    assert(value != null);

    if (this[key] == null) {
      this[key] = value;
    }
  }

  T get<T>({dynamic key, T defaultValue}) => Parse.getArgFromMap<T>(_args, key: key, defaultValue: defaultValue);

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

  void clear() => _args.clear();

  @override
  void dispose() {
    _args.clear();
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('--- args ---');
    _args.forEach((key, value) => buffer.writeln('$key: $value'));
    buffer.writeln('-----------');

    return buffer.toString();
  }
}
