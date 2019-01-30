import 'package:flutter_control/core.dart';

/// AppFactory for initializing and storing objects.
class AppFactory {
  static final AppFactory instance = AppFactory._();

  AppFactory._();

  /// Returns instance of AppFactory for given context.
  /// Currently is context ignored.
  /// AppFactory is now initialized as singleton.
  static AppFactory of([dynamic context]) => instance;

  /// Stored objects for global use.
  final _items = Map<String, dynamic>();

  /// Stored Getters for object initialization.
  final _initializers = Map<Type, Getter>();

  /// Initializes default items and initializers in factory.
  void init({Map<String, dynamic> items, Map<Type, Getter> initializers}) {
    if (items != null) {
      _items.addAll(items);
    }

    if (initializers != null) {
      _initializers.addAll(initializers);
    }
  }

  /// Adds action to initialize object.
  void addInitializer<T>(Getter<T> initializer) {
    _initializers[T] = initializer;
  }

  /// Adds object with given key for global use.
  void addItem(String key, dynamic object) {
    if (key == null || key.isEmpty) {
      key = object.toString();
    }

    _items[key] = object;
  }

  /// returns object of requested type by given key.
  /// nullable
  T getItem<T>(String key, [List args]) {
    final item = _items[key] as T;

    if (item != null && item is Initializable) {
      item.onInit(args);
    }

    return item;
  }

  /// returns object of requested type.
  /// nullable
  T getItemByType<T>([List args]) {
    T result;

    for (final item in _items.values) {
      if (item.runtimeType == T) {
        result = item as T;
      }
    }

    if (_initializers.containsKey(T)) {
      result = _initializers[T]() as T;
    }

    if (result != null && result is Initializable) {
      result.onInit(args);
    }

    return result;
  }

  /// returns new object of requested type.
  /// nullable
  T initItem<T>([List args]) {
    if (_initializers.containsKey(T)) {
      final item = _initializers[T]() as T;

      if (item is Initializable) {
        item.onInit(args);
      }
    }

    return null;
  }

  /// removes item of given key.
  T removeItem<T>(String key) {
    return _items.remove(key) as T;
  }

  /// removes all items of given type
  void removeItemByType(Type type) {
    _items.removeWhere((key, item) => item.runtimeType == type);
  }

  /// removes initializer of given Type.
  void removeInitializer(Type type) {
    _initializers.remove(type);
  }
}
