import 'package:flutter_control/core.dart';

typedef InitInjection<T> = void Function(T item, dynamic args);

abstract class Injector {
  void inject<T>(T item, dynamic args);

  static Injector of(Map<Type, InitInjection> injectors, {InitInjection other}) => BaseInjector(injectors: injectors, other: other);
}

class FlutterControl {
  static get isInitialized => ControlFactory._instance.isInitialized;

  static bool init({
    bool debug: false,
    String defaultLocale,
    Map<String, String> locales: const {'en': null},
    Map entries: const {},
    Map<Type, Initializer> initializers: const {},
    Initializer theme,
    Injector injector,
  }) {
    assert(locales != null || locales.length > 0, "Locales can't be empty or NULL");
    assert(entries != null, "Entries can't be NULL");
    assert(initializers != null, "Initializers can't be NULL");

    if (isInitialized) {
      return false;
    }

    ControlFactory._instance.debug = debug;

    final localizationAssets = List<LocalizationAsset>();
    locales.forEach((key, value) => localizationAssets.add(LocalizationAsset(key, value)));

    entries[BasePrefs] = BasePrefs();
    entries[BaseLocalization] = BaseLocalization(
      defaultLocale ?? localizationAssets[0].locale,
      localizationAssets,
    )..debug = debug;

    initializers[ControlTheme] = theme ?? (context) => ControlTheme(context);

    ControlFactory._instance.initialize(
      items: entries,
      initializers: initializers,
      injector: injector,
    );

    return isInitialized;
  }

  static Future<LocalizationArgs> loadLocalization({
    @required BuildContext context,
    bool loadDefaultLocale: true,
  }) async {
    assert(ControlFactory._instance.isInitialized, 'Factory must be initialized !');

    final localization = ControlProvider.get<BaseLocalization>();

    assert(localization != null, 'Localization must be in Factory !');

    LocalizationArgs args;

    if (loadDefaultLocale) {
      args = await localization.loadDefaultLocalization();
    }

    args = await localization.changeToSystemLocale(context);

    return args;
  }
}

/// Shortcut class to get objects from [ControlFactory]
class ControlProvider<T> extends StatelessWidget {
  /// returns object of requested type by given [key] or [Type] from [ControlFactory].
  /// check [ControlFactory] for more info.
  /// nullable
  static T get<T>([dynamic key, dynamic args]) => ControlFactory._instance.get<T>(key, args);

  /// Stores [value] with given [key] in [ControlFactory].
  /// Object with same [key] previously stored in factory is overridden.
  /// When given [key] is null, then key is [T] or generated from [Type] of given [value].
  /// returns key of stored object.
  static dynamic set<T>({dynamic key, @required dynamic value}) => ControlFactory._instance.set<T>(key: key, value: value);

  /// returns new object of requested type via initializer in [ControlFactory].
  /// nullable
  static T init<T>([dynamic args]) => ControlFactory._instance.init(args);

  /// Injects and initializes given [item] with [args].
  /// [Initializable.init] is called only when [args] are not null.
  static void inject<T>(dynamic item, {dynamic args}) => ControlFactory._instance.inject(item, args: args);

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  final dynamic factoryKey;
  final dynamic args;
  final ControlWidgetBuilder<T> builder;

  ControlProvider({
    Key key,
    this.factoryKey,
    this.args,
    @required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context, get<T>(factoryKey, args));
}

/// Shortcut class to work with global stream of [ControlFactory].
class BroadcastProvider {
  /// Subscription to global stream.
  static GlobalSubscription<T> subscribe<T>(dynamic key, ValueChanged<T> onData) => ControlFactory._instance._broadcast.subscribe(key, onData);

  /// Subscription to global stream.
  static GlobalSubscription subscribeEvent(dynamic key, VoidCallback callback) => ControlFactory._instance._broadcast.subscribeEvent(key, callback);

  /// Sets data to global stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores value for future subs and notifies them during [subscribe] phase.
  static void broadcast(dynamic key, dynamic value, {bool store: false}) => ControlFactory._instance._broadcast.broadcast(key, value, store: store);

  /// Sets data to global stream.
  /// Subs with same [key] will be notified.
  static void broadcastEvent(dynamic key) => ControlFactory._instance._broadcast.broadcastEvent(key);
}

/// Factory for initializing and storing objects.
/// Factory also creates global subscription stream driven by keys. Access this stream via [BroadcastProvider].
///
/// Fill [ControlBase.entries] for initial items to store inside factory.
/// Fill [ControlBase.initializers] for initial builders to store inside factory.
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
  Injector _injector;

  /// Factory initialize state.
  bool _initialized = false;

  /// Checks if Factory is initialized. [ControlFactory.initialize] can be called only once.
  bool get isInitialized => _initialized;

  bool debug = false;

  /// Initializes default items and initializers in factory.
  void initialize({Map items, Map<Type, Initializer> initializers, Injector injector}) {
    if (_initialized) {
      return;
    }

    _initialized = true;

    _items[ControlFactory] = this;
    _items[ControlBroadcast] = _broadcast;

    setInjector(injector);

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

  void setInjector(Injector injector) {
    _injector = injector ?? BaseInjector();

    _items[Injector] = _injector;
  }

  /// Stores [value] with given [key] for later use - [get].
  /// Object with same [key] previously stored in factory is overridden.
  /// When given [key] is null, then key is [T] or generated from [Type] of given [value].
  /// returns key of stored object.
  dynamic set<T>({dynamic key, @required dynamic value}) {
    if (key == null) {
      key = T != dynamic ? T : value.runtimeType;
    }

    assert(() {
      if (_items.containsKey(key) && _items[key] != value) {
        printDebug('Factory already contains key: ${key.toString()}. Value of this key will be overriden.');
      }
      return true;
    }());

    _items[key] = value;

    return key;
  }

  /// returns object of requested type by given key or by Type.
  /// when [args] are not empty and object is [Initializable], then [Initializable.init] is called
  /// when [T] is passed to initializer and [args] are null, then [key] is used as arguments for [CControlFactory.init].
  /// nullable
  T get<T>([dynamic key, dynamic args]) {
    if (key == null) {
      key = T;
    }

    if (_items.containsKey(key)) {
      final item = _items[key] as T;

      if (item != null) {
        inject(item, args: args);
        return item;
      }
    }

    for (final item in _items.values) {
      if (item is T) {
        inject(item, args: args);
        return item;
      }
    }

    return init<T>(args ?? key);
  }

  /// returns new object of requested type.
  /// initializer must be specified - [setInitializer]
  /// nullable
  T init<T>([dynamic args]) {
    final initializer = findInitializer<T>();

    if (initializer != null) {
      args ??= get<AppControl>()?.rootContext;

      final item = initializer(args);

      inject<T>(item, args: args);

      return item;
    }

    return null;
  }

  /// Injects and initializes given [item] with [args].
  /// [Initializable.init] is called only when [args] are not null.
  void inject<T>(dynamic item, {dynamic args}) {
    _injector.inject<T>(item, args);

    if (item is Initializable && args != null) {
      item.init(args is Map ? args : Parse.toMap(args));
    }
  }

  /// Looks for item by [Type] in collection.
  /// [includeFactory] to search in factory too.
  /// [defaultValue] is returned if nothing found.
  T find<T>(dynamic collection, {bool includeFactory: true, T defaultValue, Map args}) {
    final item = Parse.getArg<T>(collection);

    if (item != null) {
      return item;
    }

    if (includeFactory) {
      return get<T>(null, args) ?? defaultValue;
    }

    return defaultValue;
  }

  Initializer<T> findInitializer<T>() {
    if (_initializers.containsKey(T)) {
      return _initializers[T];
    } else {
      final key = _initializers.keys.firstWhere((item) => item is T, orElse: () => null);

      if (key != null) {
        return _initializers[key];
      }
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

  /// Clears whole Factory.
  void clear() {
    _items.clear();
    _initializers.clear();
    _initialized = false;
    _injector = null;
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
    clear();

    _broadcast.dispose();
  }
}

/// Global stream to broadcast data and events.
class ControlBroadcast implements Disposable {
  /// List of active subs.
  final _globalSubscriptions = List<GlobalSubscription>();

  /// Last available value for subs.
  final _globalValue = Map();

  int get subCount => _globalSubscriptions.length;

  /// Subscription to global stream
  GlobalSubscription<T> subscribe<T>(dynamic key, ValueChanged<T> onData) {
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
  GlobalSubscription subscribeEvent(dynamic key, VoidCallback callback) {
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
  int broadcast(dynamic key, dynamic value, {bool store: false}) {
    int count = 0;

    if (store) {
      _globalValue[key] = value;
    }

    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, value)) {
        count++;
        sub._notify(value);
      }
    });

    return count;
  }

  /// Sets data to global stream.
  /// Subs with same [key] will be notified.
  int broadcastEvent(dynamic key) {
    int count = 0;

    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, null)) {
        count++;
        sub._notify(null);
      }
    });

    return count;
  }

  void clear() {
    _globalSubscriptions.forEach((sub) => sub._parent = null);
    _globalSubscriptions.clear();
    _globalValue.clear();
  }

  @override
  void dispose() {
    clear();
  }
}

class GlobalSubscription<T> implements Disposable {
  /// Key of global sub.
  /// [ControlFactory.broadcast]
  final dynamic key;

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
  bool isValidForBroadcast(dynamic key, dynamic value) => _active && (value == null || value is T) && (key == null || key == this.key);

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

class BaseInjector implements Injector, Disposable {
  final _injectors = Map<Type, InitInjection>();
  InitInjection _other;

  BaseInjector({Map<Type, InitInjection> injectors, InitInjection other}) {
    if (injectors != null) {
      _injectors.addAll(injectors);
    }

    _other = other;
  }

  void setInjector<T>(InitInjection<T> inject) {
    if (T == dynamic) {
      _other = inject;
      return;
    }

    assert(() {
      if (_injectors.containsKey(T)) {
        printDebug('Injector already contains type: ${T.toString()}. Injection of this type will be overriden.');
      }
      return true;
    }());

    _injectors[T] = (item, args) => inject(item, args);
  }

  @override
  void inject<T>(dynamic item, dynamic args) {
    final injector = findInjector<T>(item.runtimeType);

    if (injector != null) {
      injector(item, args);
    }
  }

  InitInjection findInjector<T>(Type type) {
    if (T != dynamic && _injectors.containsKey(T)) {
      return _injectors[T];
    }

    if (type != null && _injectors.containsKey(type)) {
      return _injectors[type];
    }

    if (T != dynamic) {
      final key = _injectors.keys.firstWhere((item) => item.runtimeType is T, orElse: () => null);

      if (key != null) {
        return _injectors[key];
      }
    }

    return _other;
  }

  BaseInjector combine(BaseInjector other) => BaseInjector(
        injectors: {
          ..._injectors,
          ...other._injectors,
        },
        other: _other ?? other._other,
      );

  @override
  void dispose() {
    _injectors.clear();
    _other = null;
  }
}
