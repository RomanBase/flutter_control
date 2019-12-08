import 'package:flutter_control/core.dart';

typedef InitInjection = dynamic Function(dynamic item, Map args);

/// Shortcut class to get objects from [ControlFactory]
class ControlProvider {
  /// deprecated - use [ControlProvider.get] instead.
  ///
  /// returns object of requested type by given [key] or [Type] from [ControlFactory].
  /// check [ControlFactory] for more info.
  /// nullable
  @deprecated
  static T of<T>([dynamic key]) => ControlFactory._instance.get<T>(key);

  /// returns object of requested type by given [key] or [Type] from [ControlFactory].
  /// check [ControlFactory] for more info.
  /// nullable
  static T get<T>([dynamic key]) => ControlFactory._instance.get<T>(key);

  /// Stores [value] with given [key] in [ControlFactory].
  /// Object with same [key] previously stored in factory is overridden.
  /// When given [key] is null, then key is [T] or generated from [Type] of given [value].
  /// returns key of stored object.
  static dynamic set<T>({dynamic key, @required dynamic value}) => ControlFactory._instance.set<T>(key: key, value: value);

  /// returns new object of requested type via initializer in [ControlFactory].
  /// nullable
  static T init<T>([dynamic args]) => ControlFactory._instance.init(args);
}

/// Shortcut class to work with global stream of [ControlFactory].
class BroadcastProvider {
  /// Subscription to global stream.
  static GlobalSubscription<T> subscribe<T>(String key, ValueChanged<T> onData) => ControlFactory._instance._broadcast.subscribe(key, onData);

  /// Subscription to global stream.
  static GlobalSubscription subscribeEvent(String key, VoidCallback callback) => ControlFactory._instance._broadcast.subscribeEvent(key, callback);

  /// Sets data to global stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores value for future subs and notifies them during [subscribe] phase.
  static void broadcast(String key, dynamic value, {bool store: false}) => ControlFactory._instance._broadcast.broadcast(key, value, store: store);

  /// Sets data to global stream.
  /// Subs with same [key] will be notified.
  static void broadcastEvent(String key) => ControlFactory._instance._broadcast.broadcastEvent(key);
}

/// Factory for initializing and storing objects.
/// Factory also creates global subscription stream driven by keys. Access this stream via [BroadcastProvider].
///
/// When app is used with [BaseApp] and [AppControl] factory automatically holds [AppControl], [BaseLocalization] and [BasePrefs].
/// Fill [BaseApp.entries] for initial items to store inside factory.
/// Fill [BaseApp.initializers] for initial builders to store inside factory.
class ControlFactory implements Disposable {
  /// Instance of AppFactory.
  static final ControlFactory _instance = ControlFactory._();

  /// Default constructor
  ControlFactory._();

  /// Returns instance of [ControlFactory] for given context.
  /// Currently is context ignored and exist only one instance of factory.
  static ControlFactory of([dynamic context]) => _instance;

  /// Stored objects for global use.
  final _items = Map();

  /// Stored Getters for object initialization.
  final _initializers = Map<Type, Initializer>();

  /// Global stream of values and events.
  final _broadcast = ControlBroadcast();

  /// Custom item initialization.
  InitInjection _initInjection;

  /// Factory initialize state.
  bool _initialized = false;

  /// Checks if Factory is initialized. [ControlFactory.initialize] can be called only once.
  bool get isInitialized => _initialized;

  /// Initializes default items and initializers in factory.
  void initialize({Map items, Map<Type, Initializer> initializers}) {
    if (_initialized) {
      return;
    }

    _initialized = true;

    _items[ControlKey.factory] = this;
    _items[ControlKey.broadcast] = _broadcast;

    if (items != null) {
      _items.addAll(items);
    }

    if (initializers != null) {
      _initializers.addAll(initializers);
    }

    _items.forEach((key, value) {
      if (value is Initializable) {
        value.init(null);
        printDebug('factory init $key - $value - ${value.hashCode}');
      }
    });
  }

  /// Stores initializer for later use - [init] or [get].
  void setInitializer<T>(Initializer<T> initializer) {
    assert(() {
      if (_initializers.containsKey(T)) {
        printDebug('Factory already contains key: ${T.runtimeType.toString()}. Value of this key will be overriden.');
      }
      return true;
    }());

    _initializers[T] = initializer;
  }

  void setInitInjection(InitInjection injection) => _initInjection = injection;

  /// Stores [value] with given [key] for later use - [get].
  /// Object with same [key] previously stored in factory is overridden.
  /// When given [key] is null, then key is [T] or generated from [Type] of given [value].
  /// returns key of stored object.
  dynamic set<T>({dynamic key, @required dynamic value}) {
    if (key == null) {
      key = T ?? value.runtimeType;
    }

    assert(() {
      if (_items.containsKey(key)) {
        printDebug('Factory already contains key: ${key.toString()}. Value of this key will be overriden.');
      }
      return true;
    }());

    _items[key] = value;

    return key;
  }

  /// returns object of requested type by given key or by Type.
  /// when [args] are not empty and object is [Initializable], then [Initializable.init] is called
  /// nullable
  T get<T>([dynamic key, Map args]) {
    if (key == null) {
      key = T;
    }

    final item = _items[key] as T;

    if (item != null) {
      _initItem(item, args: args, forceInit: false);
      return item;
    }

    for (final item in _items.values) {
      if (item is T) {
        _initItem(item, args: args, forceInit: false);
        return item;
      }
    }

    return init<T>();
  }

  /// Looks for item by [Type] in collection.
  /// [includeFactory] to search in factory too.
  /// [defaultValue] is returned if nothing found.
  T find<T>(dynamic collection, {bool includeFactory: true, T defaultValue}) {
    final item = Parse.getArg(collection);

    if (item != null) {
      return item;
    }

    if (includeFactory) {
      return get<T>() ?? defaultValue;
    }

    return defaultValue;
  }

  /// returns new object of requested type.
  /// initializer must be specified - [setInitializer]
  /// nullable
  T init<T>([dynamic args, bool forceInit = false]) {
    if (_initializers.containsKey(T)) {
      final item = _initializers[T](args) as T;

      _initItem(item, args: args, forceInit: forceInit);

      return item;
    }

    return null;
  }

  /// returns new object of requested type.
  /// initializer must be specified - [setInitializer]
  /// nullable
  void _initItem(dynamic item, {dynamic args, bool forceInit: false}) {
    if (_initInjection != null) {
      _initInjection(item, args);
    }

    if (item is Initializable && (args != null || forceInit)) {
      item.init(args is Map ? args : Parse.toMap(args));
    }
  }

  /// Removes item of given key or all items of given type.
  void remove<T>([String key]) {
    if (key == null) {
      _items.removeWhere((key, value) => value is T);
    } else {
      _items.remove(key);
    }
  }

  /// Removes initializer of given Type.
  void removeInitializer(Type type) {
    _initializers.remove(type);
  }

  /// Removes all items of given type
  void removeAll(Type type, {bool includeInitializers: false}) {
    _items.removeWhere((key, item) => item.runtimeType == type);

    if (includeInitializers) {
      removeInitializer(type);
    }
  }

  /// Checks if key/type/object is in Factory.
  bool contains(dynamic value) {
    if (containsKey(value)) {
      return true;
    }

    if (value is Type) {
      if (containsKey(value.runtimeType)) {
        return true;
      }

      //TODO: subtype
      if (_items.values.firstWhere((item) => item.runtimeType == value, orElse: () => null) != null || _initializers.keys.firstWhere((item) => item.runtimeType == value, orElse: () => null) != null) {
        return true;
      }
    }

    return _items.values.contains(value);
  }

  /// Checks if key is in Factory.
  bool containsKey(dynamic key) => _items.containsKey(key) || key is Type && _initializers.containsKey(key);

  /// Checks if Type is in Factory.
  bool containsType<T>() {
    for (final item in _items.values) {
      if (item.runtimeType == T) {
        return true;
      }
    }

    return _initializers.containsKey(T);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('--- Items ---');
    _items.forEach((key, value) => buffer.writeln('$key - $value'));

    buffer.writeln('--- Initializers ---');
    _initializers.forEach((key, value) => buffer.writeln('$key - $value'));

    buffer.writeln('--- Subscriptions ---');
    _broadcast._globalSubscriptions.forEach((item) => buffer.writeln('${item.key} - ${_broadcast._globalValue[item.key]}'));

    return buffer.toString();
  }

  @override
  void dispose() {
    _items.clear();
    _initializers.clear();
  }
}

/// Global stream to broadcast data and events.
class ControlBroadcast implements Disposable {
  /// List of active subs.
  final _globalSubscriptions = List<GlobalSubscription>();

  /// Last available value for subs.
  final _globalValue = Map<String, dynamic>();

  /// Subscription to global stream
  GlobalSubscription<T> subscribe<T>(String key, ValueChanged<T> onData) {
    assert(onData != null);

    final sub = GlobalSubscription<T>(key);

    sub._parent = this;
    sub._onData = onData;

    _globalSubscriptions.add(sub);

    final lastValue = _globalValue[sub.key];

    if (lastValue != null && sub.isValidForBroadcast(sub.key, lastValue)) {
      sub._notify(lastValue);
    }

    return sub;
  }

  /// Subscription to global stream
  GlobalSubscription subscribeEvent(String key, VoidCallback callback) {
    return subscribe(key, (_) => callback());
  }

  /// Cancels subscriptions to global stream
  void cancelSubscription(GlobalSubscription sub) {
    sub.pause();
    _globalSubscriptions.remove(sub);
  }

  /// Sets data to global stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores value for future subs and notifies them during [subscribe] phase.
  void broadcast(String key, dynamic value, {bool store: false}) {
    if (store) {
      _globalValue[key] = value;
    }

    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, value)) {
        sub._notify(value);
      }
    });
  }

  /// Sets data to global stream.
  /// Subs with same [key] will be notified.
  void broadcastEvent(String key) {
    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, null)) {
        sub._notify(null);
      }
    });
  }

  @override
  void dispose() {
    _globalSubscriptions.forEach((sub) => sub._parent = null);

    _globalSubscriptions.clear();
    _globalValue.clear();
  }
}

class GlobalSubscription<T> implements Disposable {
  /// Key of global sub.
  /// [ControlFactory.broadcast]
  final String key;

  /// Parent of this sub - who creates and setup this sub.
  ControlBroadcast _parent;

  /// Callback from sub.
  /// [ControlFactory.broadcast]
  ValueChanged<T> _onData;

  bool _active = true;

  /// Checks if parent is valid and sub is active.
  bool get isActive => _parent != null && _active;

  /// Default constructor.
  GlobalSubscription(this.key);

  /// Checks if [key] and [value] type is eligible for this sub.
  bool isValidForBroadcast(String key, dynamic value) => _active && (value == null || value is T) && (key == null || key == this.key);

  /// Pauses this subscription and [ControlFactory] broadcast will skip this sub.
  void pause() => _active = false;

  /// Resumes this subscription and [ControlFactory] broadcast will again starts notifying this sub.
  void resume() => _active = true;

  void _notify(dynamic value) => _onData(value as T);

  /// Cancels subscription to global stream in [ControlFactory].
  void cancel() {
    _active = false;
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
