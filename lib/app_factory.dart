import 'dart:async';

import 'package:flutter_control/core.dart';

class GlobalSubscription<T> implements Disposable {
  AppFactory _parent;

  ValueChanged<T> _onData;

  final String key;

  GlobalSubscription(this.key);

  bool isValidForBroadcast(String key, dynamic value) => value is T && (key == null || key == this.key);

  @override
  void dispose() {
    if (_parent != null) {
      _parent.cancelSubscription(this);
      _parent = null;
    }
  }
}

/// AppFactory for initializing and storing objects.
class AppFactory implements Disposable {
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

  final _globalSubscriptions = List<GlobalSubscription>();
  final _globalValue = Map<String, dynamic>();

  /// Initializes default items and initializers in factory.
  void init({Map<String, dynamic> items, Map<Type, Getter> initializers}) {
    if (items != null) {
      _items.addAll(items);
    }

    if (initializers != null) {
      _initializers.addAll(initializers);
    }

    _items.forEach((key, value) {
      if (value is Initializable) {
        value.onInit(null);
      }
    });
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

    if (item != null && item is Initializable && args != null) {
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

  /// Subscription to global stream
  GlobalSubscription<T> subscribe<T>(String key, void onData(T data)) {
    assert(onData != null);

    final sub = GlobalSubscription<T>(key);

    sub._parent = this;
    sub._onData = onData;

    _globalSubscriptions.add(sub);

    final lastValue = _globalValue[sub.key];

    if (lastValue != null && sub.isValidForBroadcast(sub.key, lastValue)) {
      sub._onData(lastValue);
    }

    return sub;
  }

  /// Cancels subscriptions to global stream
  void cancelSubscription(GlobalSubscription sub) => _globalSubscriptions.remove(sub);

  /// Sets data to global stream
  void broadcast(String key, dynamic value) {
    _globalValue[key] = value;

    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, value)) {
        sub._onData(value);
      }
    });
  }

  @override
  void dispose() {
    _globalSubscriptions.clear();
    _globalValue.clear();
  }
}
