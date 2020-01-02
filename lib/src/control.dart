import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

typedef InitInjection<T> = void Function(T item, dynamic args);

abstract class Injector {
  void inject<T>(T item, dynamic args);

  static Injector of(Map<Type, InitInjection> injectors, {InitInjection other}) => BaseInjector(injectors: injectors, other: other);
}

class Control {
  static get isInitialized => factory().isInitialized;

  static get debug => factory().debug;

  static ControlFactory factory() => ControlFactory._instance;

  static ControlScope of([BuildContext context]) {
    ControlScope scope;

    if (context != null) {
      scope = context.findAncestorWidgetOfExactType<ControlScope>();
    }

    return scope ?? ControlProvider.get<ControlScope>();
  }

  static bool init({
    bool debug,
    String defaultLocale,
    Map<String, String> locales,
    Map entries,
    Map<Type, Initializer> initializers,
    Injector injector,
    List<PageRouteProvider> routes,
    Initializer theme,
  }) {
    if (isInitialized) {
      return false;
    }

    debug ??= kDebugMode;
    ControlFactory._instance.debug = debug;

    locales ??= {'en': null};
    entries ??= {};
    initializers ??= {};

    final localizationAssets = List<LocalizationAsset>();
    locales.forEach((key, value) => localizationAssets.add(LocalizationAsset(key, value)));

    entries[ControlScope] = ControlScope.empty();
    entries[BasePrefs] = BasePrefs();
    entries[RouteStorage] = RouteStorage(routes);
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

  static Future<LocalizationArgs> initLocalization({
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
  /// Returns object of requested type by given [key] or by [Type] from [ControlFactory].
  /// When [args] are not empty and object is [Initializable], then [Initializable.init] is called.
  /// When [T] is passed to initializer and [args] are null, then [key] is used as arguments for [ControlFactory.init].
  /// nullable
  static T get<T>([dynamic key, dynamic args]) => ControlFactory._instance.get<T>(key, args);

  /// Stores [value] with given [key] in [ControlFactory].
  /// Object with same [key] previously stored in factory is overridden.
  /// When given [key] is null, then key is [T] or generated from [Type] of given [value].
  /// returns key of stored object.
  static dynamic set<T>({dynamic key, @required dynamic value}) => ControlFactory._instance.set<T>(key: key, value: value);

  /// returns new object of requested [Type] via initializer in [ControlFactory].
  /// nullable
  static T init<T>([dynamic args]) => ControlFactory._instance.init(args);

  /// Injects and initializes given [item] with [args].
  /// [Initializable.init] is called only when [args] are not null.
  static void inject<T>(dynamic item, {dynamic args}) => ControlFactory._instance.inject(item, args: args);

  /// Executes sequence of functions to retrieve expect object.
  /// Look up in [source] for item via [Parse.getArg].
  /// Then [ControlFactory.get] / [ControlFactory.init] is executed.
  /// nullable
  static T resolve<T>(dynamic source, {dynamic key, dynamic args, T defaultValue}) => ControlFactory._instance.resolve<T>(source, key: key, args: args, defaultValue: defaultValue);

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

class ControlProviderGroup extends StatelessWidget {
  final List<dynamic> factoryKeys;
  final dynamic args;
  final ControlWidgetBuilder<List> builder;

  ControlProviderGroup({
    Key key,
    this.factoryKeys,
    this.args,
    @required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context, getControls());

  List getControls() => factoryKeys.map((key) => ControlProvider.get(key, args)).toList();
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
class ControlFactory with Disposable {
  /// Instance of AppFactory.
  static final ControlFactory _instance = ControlFactory._();

  /// Default constructor
  ControlFactory._();

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
  void initialize({
    Map items,
    Map<Type, Initializer> initializers,
    Injector injector,
  }) {
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
    _injector = injector;

    if (injector == null && _items.containsKey(Injector)) {
      _items.remove(Injector);
    } else {
      _items[Injector] = injector;
    }
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

  /// Returns object of requested type by given [key] or by [Type].
  /// When [args] are not empty and object is [Initializable], then [Initializable.init] is called.
  /// When [T] is passed to initializer and [args] are null, then [key] is used as arguments for [ControlFactory.init].
  /// Finally object is Injected [ControlFactory.inject] with given [args].
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
      args ??= get<ControlScope>()?.rootContext;

      final item = initializer(args);

      inject<T>(item, args: args);

      return item;
    }

    return null;
  }

  /// Injects and initializes given [item] with [args].
  /// [Injector.inject] is called even if [args] are null.
  /// [Initializable.init] is called only when [args] are not null.
  void inject<T>(dynamic item, {dynamic args, bool force: true}) {
    if (_injector != null) {
      _injector.inject<T>(item, args);
    }

    if (item is Initializable && args != null) {
      item.init(args is Map ? args : Parse.toMap(args));
    }
  }

  /// Executes sequence of functions to retrieve expect object.
  /// Look up in [source] for item via [Parse.getArg].
  /// Then [ControlFactory.get] and [ControlFactory.init] is executed.
  /// Finally [ControlFactory.inject] is called.
  /// nullable
  T resolve<T>(dynamic source, {dynamic key, dynamic args, T defaultValue}) {
    final item = Parse.getArg<T>(source, key: key);

    if (item != null) {
      inject(item, args: args);
      return item;
    }

    return get<T>(key, args) ?? defaultValue;
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
  void remove<T>([dynamic key]) {
    if (key == null && T != dynamic) {
      key = T;
    }

    if (key != null) {
      if (_items.containsKey(key)) {
        _items.remove(key);
      } else {
        _items.removeWhere((key, value) => value is T);
      }
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

    return buffer.toString();
  }

  @override
  void dispose() {
    clear();

    _broadcast.dispose();
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
