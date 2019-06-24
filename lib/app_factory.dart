import 'package:flutter_control/core.dart';

class GlobalSubscription<T> implements Disposable {
  /// Key of global sub.
  /// [AppFactory.broadcast]
  final String key;

  /// Parent of this sub - who creates and setup this sub.
  AppFactory _parent;

  /// Callback from sub.
  /// [AppFactory.broadcast]
  ValueChanged<T> _onData;

  /// Default constructor.
  GlobalSubscription(this.key);

  /// Checks if [key] and [value] type is eligible for this sub.
  bool isValidForBroadcast(String key, dynamic value) => value is T && (key == null || key == this.key);

  /// Cancels subscription to global stream in [AppFactory].
  void cancel() {
    if (_parent != null) {
      _parent.cancelSubscription(this);
    }
  }

  @override
  void dispose() {
    cancel();
    _parent = null;
  }
}

/// Factory for initializing and storing objects.
/// Factory also creates global subscription stream driven by keys.
///
/// When app is used with [BaseApp] and [AppControl] factory automatically holds [AppControl], [AppLocalization] and [AppPrefs].
/// Fill [BaseApp.entries] for initial items to store inside factory.
class AppFactory implements Disposable {
  /// Instance of AppFactory.
  static final AppFactory _instance = AppFactory._();

  /// Default constructor
  AppFactory._();

  /// Returns instance of [AppFactory] for given context.
  /// Currently is context ignored and exist only one instance of factory.
  static AppFactory of([dynamic context]) => _instance;

  /// Stored objects for global use.
  final _items = Map<String, dynamic>();

  /// Stored Getters for object initialization.
  final _initializers = Map<Type, Getter>();

  /// List of active subs.
  final _globalSubscriptions = List<GlobalSubscription>();

  /// Last available value for subs.
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
        value.init(null);
      }
    });
  }

  /// Stores initializer for later use - [initItem].
  void addInitializer<T>(Getter<T> initializer) {
    _initializers[T] = initializer;
  }

  /// Stores [object] with given [key] for later use - [getItem] and [getItemByType].
  /// Object with same [key] previously stored in factory is overridden.
  void addItem(String key, dynamic object) {
    printDebug("factory add: $key");

    if (key == null || key.isEmpty) {
      key = object.toString();
    }

    _items[key] = object;
  }

  /// returns object of requested type by given key.
  /// check [getItemByType] or [getItemInit] for more complex getters
  /// nullable
  T getItem<T>(String key) => _items[key] as T;

  /// returns object of requested type by given key.
  /// when [args] are not empty and object is [Initializable], then [Initializable.init] is called
  /// nullable
  T getItemInit<T>(String key, [Map args]) {
    final item = _items[key] as T;

    if (item != null && item is Initializable && args != null) {
      item.init(args);
    }

    return item;
  }

  /// returns object of requested type.
  /// nullable
  T getItemByType<T>([Map args]) {
    T result;

    for (final item in _items.values) {
      if (item.runtimeType == T) {
        result = item as T;
        break;
      }
    }

    if (_initializers.containsKey(T)) {
      result = _initializers[T]() as T;
    }

    if (result != null && result is Initializable) {
      result.init(args);
    }

    return result;
  }

  T findItem<T>(Iterable collection, {T defaultValue}) {
    if (collection != null) {
      for (final item in collection) {
        if (item.runtimeType == T) {
          return item as T;
        }
      }
    }

    return defaultValue;
  }

  /// returns new object of requested type.
  /// initializer must be specified - [addInitializer]
  /// nullable
  T initItem<T>([Map args]) {
    if (_initializers.containsKey(T)) {
      final item = _initializers[T]() as T;

      if (item is Initializable) {
        item.init(args);
      }

      return item;
    }

    return null;
  }

  /// Removes item of given key.
  T removeItem<T>(String key) {
    return _items.remove(key) as T;
  }

  /// Removes all items of given type
  void removeItemByType(Type type) {
    _items.removeWhere((key, item) => item.runtimeType == type);
  }

  /// Removes initializer of given Type.
  void removeInitializer(Type type) {
    _initializers.remove(type);
  }

  /// Checks if key is in Factory.
  bool contains(String key) => _items.containsKey(key);

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

  /// Sets data to global stream.
  /// Subs with same [key] a [value] type will be notified.
  /// [store] - stores value for future subs and notifies them during [subscribe] phase.
  void broadcast(String key, dynamic value, {bool store: false}) {
    if (store) {
      _globalValue[key] = value;
    }

    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, value)) {
        sub._onData(value);
      }
    });
  }

  @override
  void dispose() {
    _items.clear();
    _initializers.clear();
    _globalSubscriptions.clear();
    _globalValue.clear();
  }
}
