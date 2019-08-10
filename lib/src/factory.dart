import 'package:flutter_control/core.dart';

class GlobalSubscription<T> implements Disposable {
  /// Key of global sub.
  /// [ControlFactory.broadcast]
  final String key;

  /// Parent of this sub - who creates and setup this sub.
  ControlFactory _parent;

  /// Callback from sub.
  /// [ControlFactory.broadcast]
  ValueChanged<T> _onData;

  bool _active = true;

  /// Checks if parent is valid and sub is active.
  bool get isActive => _parent != null && _active;

  /// Default constructor.
  GlobalSubscription(this.key);

  /// Checks if [key] and [value] type is eligible for this sub.
  bool isValidForBroadcast(String key, dynamic value) => _active && value is T && (key == null || key == this.key);

  /// Pauses this subscription and [ControlFactory] broadcast will skip this sub.
  void pause() => _active = false;

  /// Resumes this subscription and [ControlFactory] broadcast will again starts notifying this sub.
  void resume() => _active = true;

  void _notify(dynamic value) => _onData(value as T);

  /// Cancels subscription to global stream in [ControlFactory].
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

class ControlProvider {
  static T of<T>([String key]) => ControlFactory._instance.get<T>(key);
}

class ArgProvider {
  static T map<T>(Map map, {dynamic key, T defaultValue}) {
    if (map == null) {
      return defaultValue;
    }

    if (key != null && map.containsKey(key)) {
      return map[key];
    }

    final item = map.values.firstWhere((item) => item is T, orElse: () => null);

    return item ?? defaultValue;
  }

  static T list<T>(List list, [T defaultValue]) {
    final item = list.firstWhere((item) => item is T);

    if (item != null) {
      return item;
    }

    return defaultValue;
  }
}

/// Factory for initializing and storing objects.
/// Factory also creates global subscription stream driven by keys.
///
/// When app is used with [BaseApp] and [AppControl] factory automatically holds [AppControl], [BaseLocalization] and [BasePrefs].
/// Fill [BaseApp.entries] for initial items to store inside factory.
class ControlFactory implements Disposable {
  /// Instance of AppFactory.
  static final ControlFactory _instance = ControlFactory._();

  /// Default constructor
  ControlFactory._();

  /// Returns instance of [ControlFactory] for given context.
  /// Currently is context ignored and exist only one instance of factory.
  static ControlFactory of([dynamic context]) => _instance;

  /// Stored objects for global use.
  final _items = Map<String, dynamic>();

  /// Stored Getters for object initialization.
  final _initializers = Map<Type, Initializer>();

  /// List of active subs.
  final _globalSubscriptions = List<GlobalSubscription>();

  /// Last available value for subs.
  final _globalValue = Map<String, dynamic>();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initializes default items and initializers in factory.
  void initialize({Map<String, dynamic> items, Map<Type, Initializer> initializers}) {
    if (_initialized) {
      return;
    }

    _initialized = true;

    _items[ControlKey.factory] = this;

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
  void addInitializer<T>(Initializer<T> initializer) => _initializers[T] = initializer;

  /// Stores [object] with given [key] for later use - [get] and [getWith].
  /// Object with same [key] previously stored in factory is overridden.
  void addItem(String key, dynamic object) {
    if (key == null || key.isEmpty) {
      key = object.runtimeType.toString();
    }

    _items[key] = object;
  }

  /// Stores [object] of given Type for later use.
  /// Key is [runtimeType] of given [object].
  /// returns key of stored object.
  String add(dynamic object) {
    final key = object.runtimeType.toString();

    _items[key] = object;

    return key;
  }

  /// returns object of requested type by given key or by Type.
  /// check [getWith] for more complex getter
  /// nullable
  T get<T>([String key]) {
    if (key != null) {
      final item = _items[key] as T;

      if (item != null) {
        return item;
      }
    }

    for (final item in _items.values) {
      if (item.runtimeType == T) {
        return item;
      }
    }

    return init<T>();
  }

  /// returns object of requested type by given key.
  /// when [args] are not empty and object is [Initializable], then [Initializable.init] is called
  /// nullable
  T getWith<T>(String key, [Map args]) {
    final item = get<T>(key);

    if (item != null && item is Initializable && args != null) {
      item.init(args);
    }

    return item;
  }

  /// Looks for item by [Type] in collection.
  /// [includeFactory] to search in factory too.
  /// [defaultValue] is returned if nothing found.
  T find<T>(Iterable collection, {bool includeFactory: true, T defaultValue}) {
    if (collection != null) {
      for (final item in collection) {
        if (item.runtimeType == T) {
          return item;
        }
      }
    }

    if (includeFactory) {
      return get()<T>() ?? defaultValue;
    }

    return defaultValue;
  }

  /// returns new object of requested type.
  /// initializer must be specified - [addInitializer]
  /// nullable
  T init<T>([Map args, bool forceInit = false]) {
    if (_initializers.containsKey(T)) {
      final item = _initializers[T]() as T;

      if (item is Initializable && (args != null || forceInit)) {
        item.init(args);
      }

      return item;
    }

    return null;
  }

  /// Removes item of given key or all items of given type.
  void remove<T>([String key]) {
    if (key == null) {
      _items.removeWhere((key, value) => value is T);
    } else {
      _items.remove(key);
    }
  }

  /// Removes all items of given type
  void removeType(Type type, {bool includeInitializers: false}) {
    _items.removeWhere((key, item) => item.runtimeType == type);

    if (includeInitializers) {
      removeInitializer(type);
    }
  }

  /// Removes initializer of given Type.
  void removeInitializer(Type type) {
    _initializers.remove(type);
  }

  /// Checks if key is in Factory.
  bool contains(String key) => _items.containsKey(key);

  /// Checks if Type is in Factory.
  bool containsType<T>({bool includeInitializers: true}) {
    for (final item in _items.values) {
      if (item.runtimeType == T) {
        return true;
      }
    }

    return _initializers.containsKey(T);
  }

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
        sub._notify(value);
      }
    });
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('--- Items ---');
    _items.forEach((key, value) => buffer.writeln('$key - $value'));

    buffer.writeln('--- Initializers ---');
    _initializers.forEach((key, value) => buffer.writeln('$key - $value'));

    buffer.writeln('--- Subscriptions ---');
    _globalSubscriptions.forEach((item) => buffer.writeln('${item.key} - ${_globalValue[item.key]}'));

    return buffer.toString();
  }

  @override
  void dispose() {
    _items.clear();
    _initializers.clear();
    _globalSubscriptions.clear();
    _globalValue.clear();
  }
}
