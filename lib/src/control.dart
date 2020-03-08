import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

/// Main [Control] static class.
/// Provides easy access to most usable [Control] classes. These objects are stored in [ControlFactory] with their [Type] key.
/// Some of this classes also has custom Provider with base functionality.
///
/// Start with [Control.initControl] to initialize [ControlFactory] and other core [Control] objects.
///
/// [ControlBroadcast] - Sends data and events via global broadcast. Use [BroadcastProvider] for base and direct workflow.
/// [BaseLocalization] - Loads and stores localization data. Use it directly via [LocalizationProvider] as mixin or to find closest [BaseLocalizationDelegate] in Widget Tree.
/// [RouteStore] - Stores route builders and their paths and settings. Use [ControlRoute.of] to retrieve route. Then is possible to alter this route with new settings, path or transition.
/// [ControlScope] - This class provides access to root of Widget Tree and to [ControlRootState]. But only if [ControlRoot] Widget is used.
/// [BasePrefs] - Wrapper around [SharedPreferences].
class Control {
  /// Control is pure static class.
  /// Just hidden constructor.
  Control._();

  /// Checks if [ControlFactory] is initialized.
  ///
  /// Factory can be initialized via [Control.initControl] or [ControlFactory.initialize].
  static get isInitialized => factory().isInitialized;

  /// Checks if current settings of debug mode (this mode is set independently to [kDebugMode]) and is usable in profile/release mode.
  /// This value is also provided to [BaseLocalization] during [Control.initControl] and to various other classes.
  static get debug => factory().debug;

  /// Returns instance of [ControlFactory].
  static ControlFactory factory() => ControlFactory._instance;

  /// Returns default instance of [ControlBroadcast] - this instance is stored in [ControlFactory].
  /// Use [BroadcastProvider] for base broadcast operations.
  static ControlBroadcast broadcaster() => factory()._broadcast;

  /// Returns default instance of [Injector] - this instance is stored in [ControlFactory].
  /// Injector is set via [Control.initControl] or [ControlFactory.setInjector].
  static Injector injector() => factory()._injector;

  /// Returns default instance of [BaseLocalization] - this instance is stored in [ControlFactory].
  /// Default localization is [Map] based and it's possible to use it via [LocalizationProvider] as mixin or to find closest [BaseLocalizationDelegate] in Widget Tree.
  static BaseLocalization localization() => Control.get<BaseLocalization>();

  /// Returns scope of [ControlRoot].
  /// This scope provides access to root of Widget Tree and to [ControlRootState].
  /// But only if [ControlRoot] Widget is used.
  static ControlScope root() => ControlScope();

  /////
  /////
  /////

  /// Initializes [ControlFactory] and other core [Control] objects.
  /// Loads [BasePrefs] and [BaseLocalization], also builds [RouteStore].
  ///
  /// [debug] - Runtime debug value. This value is also provided to [BaseLocalization]. Default value is [kDebugMode].
  /// [defaultLocale] - Default (not preferred) locale. This locale can contains non-translatable values (links, etc.).
  /// [locales] - Map of locale assets {'locale', 'path'}. Use [LocalizationAsset.build] for easier setup.
  /// [entries] - Default items to store in [ControlFactory]. Use [Control.get] to retrieve this objects and [Control.set] to add new ones.
  /// [initializers] - Default factory initializers to store in [ControlFactory] Use [Control.init] or [Control.get] to retrieve concrete objects.
  /// [injector] - Injector to use after object initialization. Use [BaseInjector] for [Type] based injection.
  /// [routes] - Set of routes for [RouteStore]. Use [ControlRoute.build] to build routes and [ControlRoute.of] to retrieve route. It's possible to alter route with new settings, path or transition. [RouteStore] is also stored in [ControlFactory].
  /// [theme] - Initializer of [ControlTheme]. Set this initializer only if providing custom, extended version of [ControlTheme].
  /// [initAsync] - Custom [async] function to execute during [ControlFactory] initialization. Don't overwhelm this function - it's just for loading core settings before 'home' widget is shown.
  static bool initControl({
    bool debug,
    String defaultLocale,
    Map<String, String> locales,
    Map entries,
    Map<Type, Initializer> initializers,
    Injector injector,
    List<ControlRoute> routes,
    Initializer theme,
    Future Function() initAsync,
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
    locales.forEach((key, value) => localizationAssets.add(LocalizationAsset(key.replaceAll('-', '_'), value)));

    final prefs = BasePrefs();

    entries[BasePrefs] = prefs;
    entries[RouteStore] = RouteStore(routes);
    entries[BaseLocalization] = BaseLocalization(
      defaultLocale ?? localizationAssets[0].locale,
      localizationAssets,
    )..debug = debug;

    initializers[ControlTheme] = theme ?? (context) => ControlTheme(context);

    ControlFactory._instance.initialize(
      entries: entries,
      initializers: initializers,
      injector: injector,
      initAsync: () => FutureBlock.wait([
        prefs.init(),
        initAsync != null ? initAsync() : null,
      ]),
    );

    return true;
  }

  /////
  /////
  /////

  /// Returns object of requested type by given [key] or by [Type] from [ControlFactory].
  /// When [args] are not empty and object is [Initializable], then [Initializable.init] is called.
  /// Set [withInjector] to re-inject stored object.
  ///
  /// If object is not found in internal store, then factory tries to initialize new one via [ControlFactory.init].
  /// When [T] is passed to initializer and [args] are null, then [key] is used as arguments for [ControlFactory.init].
  /// And when initialized object is [LazyControl] then this object is stored into Factory.
  ///
  /// [Control] provides static call for this function via [Control.get].
  ///
  /// nullable
  static T get<T>({dynamic key, dynamic args, bool withInjector: true}) => factory().get<T>(key: key, args: args, withInjector: withInjector);

  /// Stores [value] with given [key] in [ControlFactory].
  /// Object with same [key] previously stored in factory is overridden.
  /// When given [key] is null, then key is [T] or generated from [Type] of given [value] - check [ControlFactory.keyOf] for more info.
  /// Returns [key] of stored [value].
  static dynamic set<T>({dynamic key, @required dynamic value}) => factory().set<T>(key: key, value: value);

  /// Returns new object of requested [Type] via initializer in [ControlFactory].
  /// When [args] are not null and initialized object is [Initializable] then [Initializable.init] is called.
  ///
  /// This function is also called when [ControlFactory.get] fails to find object in internal store and [key] is [Type].
  /// In most of cases is preferred to use more powerful [ControlFactory.get].
  ///
  /// Initializers are passed to factory during init phase or later can be added via [ControlFactory.setInitializer].
  ///
  /// [Control] provides static call for this function via [Control.init].
  ///
  /// nullable
  static T init<T>([dynamic args]) => factory().init(args);

  /// Injects and initializes given [item] with [args].

  /// [Initializable.init] is called only when [args] are not null.
  ///
  /// [Control] provides static call for this function via [Control.inject].
  static void inject<T>(dynamic item, {dynamic args}) => factory().inject(item, args: args, withInjector: true, withArgs: true);

  /// Executes sequence of functions to retrieve expected object.
  /// Look up in [source] for item via [Parse.getArg] and if object is not found then [ControlFactory.get] / [ControlFactory.init] is executed.
  /// Returns object from [source] or via [ControlFactory] or [defaultValue].
  /// nullable
  static T resolve<T>(dynamic source, {dynamic key, dynamic args, T defaultValue}) => factory().resolve<T>(source, key: key, args: args, defaultValue: defaultValue);

  /// Removes specific object with given [key] or by [Type] from [ControlFactory].
  /// When given [key] is null, then key is [T] - check [ControlFactory.keyOf] for more info.
  /// If object of given [key] is not found, then all instances of [T] are removed.
  /// Set [dispose] to dispose removed object/s.
  ///
  /// Returns number of removed items.
  static int remove<T>({dynamic key, bool dispose: false}) => factory().remove<T>(key: key, dispose: dispose);
}

/// TODO: doc
class BroadcastProvider {
  /// Subscription to global stream.
  static BroadcastSubscription<T> subscribe<T>(dynamic key, ValueChanged<T> onData) => ControlFactory._instance._broadcast.subscribe(key, onData);

  /// Subscription to global stream.
  static BroadcastSubscription subscribeEvent(dynamic key, VoidCallback callback) => ControlFactory._instance._broadcast.subscribeEvent(key, callback);

  /// Sets data to global stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores value for future subs and notifies them during [subscribe] phase.
  static void broadcast(dynamic key, dynamic value, {bool store: false}) => ControlFactory._instance._broadcast.broadcast(key, value, store: store);

  /// Sets data to global stream.
  /// Subs with same [key] will be notified.
  static void broadcastEvent(dynamic key) => ControlFactory._instance._broadcast.broadcastEvent(key);
}

/// TODO: doc
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

  Completer _completer = Completer();

  /// Initializes default items and initializers in factory.
  bool initialize({Map entries, Map<Type, Initializer> initializers, Injector injector, Future Function() initAsync}) {
    if (_initialized) {
      return false;
    }

    _initialized = true;

    _items[ControlFactory] = this;
    _items[ControlBroadcast] = _broadcast;

    setInjector(injector);

    if (entries != null) {
      _items.addAll(entries);
    }

    if (initializers != null) {
      _initializers.addAll(initializers);
    }

    _items.forEach((key, value) {
      if (value is Initializable) {
        inject(value, args: {});

        printDebug('Factory inits $key - ${value.runtimeType.toString()}');
      }

      if (value is DisposeHandler) {
        value.preferSoftDispose = true;

        printDebug('Factory prefers soft dispose of $key - ${value.runtimeType.toString()}');
      }
    });

    _initializeAsyncs(initAsync);

    _initialized = true;

    return true;
  }

  Future<void> _initializeAsyncs(Future Function() initAsync) async {
    if (initAsync != null) {
      await initAsync();
    }

    _completer.complete();
    _completer = null;
  }

  Future<void> onReady() async => _completer?.future;

  dynamic keyOf<T>({dynamic key, dynamic value}) {
    if (key == null) {
      key = T != dynamic ? T : value?.runtimeType;
    }

    return key;
  }

  /// Sets [Injector] for this Factory.
  /// Set null to remove current Injector.
  void setInjector(Injector injector) {
    _injector = injector;

    if (injector == null && _items.containsKey(Injector)) {
      _items.remove(Injector);
    } else {
      _items[Injector] = injector;
    }
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

  /// Stores [value] with given [key] in [ControlFactory].
  /// Object with same [key] previously stored in factory is overridden.
  /// When given [key] is null, then key is [T] or generated from [Type] of given [value] - check [ControlFactory.keyOf] for more info.
  /// Returns [key] of stored [value].
  ///
  /// [Control] provides static call for this function via [Control.set].
  dynamic set<T>({dynamic key, @required dynamic value}) {
    key = keyOf<T>(key: key, value: value);

    assert(key != null);
    assert(() {
      if (_items.containsKey(key) && _items[key] != value) {
        printDebug('Factory already contains key: ${key.toString()}. Value of this key will be overriden.');
      }
      return true;
    }());

    _items[key] = value;

    return key;
  }

  /// Returns object of requested type by given [key] or by [Type] from [ControlFactory].
  /// When [args] are not empty and object is [Initializable], then [Initializable.init] is called.
  /// Set [withInjector] to re-inject stored object.
  ///
  /// If object is not found in internal store, then factory tries to initialize new one via [ControlFactory.init].
  /// When [T] is passed to initializer and [args] are null, then [key] is used as arguments for [ControlFactory.init].
  /// And when initialized object is [LazyControl] then this object is stored into Factory.
  ///
  /// [Control] provides static call for this function via [Control.get].
  ///
  /// nullable
  T get<T>({dynamic key, dynamic args, bool withInjector: false}) {
    final useExactKey = key != null;
    key = keyOf<T>(key: key);

    assert(key != null);

    if (_items.containsKey(key)) {
      final item = _items[key] as T;

      if (item != null) {
        inject(item, args: args, withInjector: withInjector);
        return item;
      }
    }

    if (!useExactKey) {
      T item;

      if (T != dynamic) {
        item = _items.values.firstWhere((item) => item is T, orElse: () => null);
      } else if (key == Type) {
        item = _items.values.firstWhere((item) => item.runtimeType == key, orElse: () => null);
      }

      if (item != null) {
        inject(item, args: args, withInjector: withInjector);
        return item;
      }
    }

    final item = init<T>(args ?? key);

    if (item is LazyControl) {
      item._factoryKey = key;
      set<T>(key: key, value: item);
    }

    return item;
  }

  /// Returns new object of requested [Type] via initializer in [ControlFactory].
  /// When [args] are not null and initialized object is [Initializable] then [Initializable.init] is called.
  ///
  /// This function is also called when [ControlFactory.get] fails to find object in internal store and [key] is [Type].
  /// In most of cases is preferred to use more powerful [ControlFactory.get].
  ///
  /// Initializers are passed to factory during init phase or later can be added via [ControlFactory.setInitializer].
  ///
  /// [Control] provides static call for this function via [Control.init].
  ///
  /// nullable
  T init<T>([dynamic args]) {
    final initializer = findInitializer<T>();

    if (initializer != null) {
      args ??= Control.root()?.rootContext;

      final item = initializer(args);

      inject<T>(item, args: args);

      return item;
    }

    return null;
  }

  /// Injects and initializes given [item] with [args].
  /// Set [withInjector] to inject given object.
  /// Set [withArgs] to init given object.
  ///
  /// [Initializable.init] is called only when [args] are not null.
  ///
  /// [Control] provides static call for this function via [Control.inject].
  void inject<T>(dynamic item, {dynamic args, bool withInjector: true, bool withArgs: true}) {
    if (withInjector && _injector != null) {
      _injector.inject<T>(item, args);
    }

    if (withArgs && item is Initializable && args != null) {
      item.init(args is Map ? args : Parse.toMap(args));
    }
  }

  /// Executes sequence of functions to retrieve expected object.
  /// Look up in [source] for item via [Parse.getArg] and if object is not found then [ControlFactory.get] is executed with given [key] and [args].
  /// Returns object from [source] or from factory store/initializers or [defaultValue].
  ///
  /// [Control] provides static call for this function via [Control.inject].
  ///
  /// nullable
  T resolve<T>(dynamic source, {dynamic key, dynamic args, T defaultValue}) {
    final item = Parse.getArg<T>(source, key: key);

    if (item != null) {
      inject(item, args: args);
      return item;
    }

    return get<T>(key: key, args: args) ?? defaultValue;
  }

  /// Finds and returns [Initializer] of given [Type].
  ///
  /// [ControlFactory.init] uses this method to retrieve [Initializer].
  ///
  /// nullable
  Initializer<T> findInitializer<T>() {
    if (_initializers.containsKey(T)) {
      return _initializers[T];
    } else if (T != dynamic) {
      final key = _initializers.keys.firstWhere((item) => item is T, orElse: () => null);

      if (key != null) {
        return _initializers[key];
      }
    }

    return null;
  }

  /// Removes specific object with given [key] or by [Type] from [ControlFactory].
  /// When given [key] is null, then key is [T] - check [ControlFactory.keyOf] for more info.
  /// If object of given [key] is not found, then all instances of [T] are removed.
  /// Set [dispose] to dispose removed object/s.
  ///
  /// [Control] provides static call for this function via [Control.remove].
  ///
  /// Returns number of removed items.
  int remove<T>({dynamic key, bool dispose: false}) {
    key = keyOf<T>(key: key);

    assert(key != null);

    int count = 0;

    if (_items.containsKey(key)) {
      final item = _items.remove(key);
      if (dispose && item is Disposable) {
        item.dispose();
      }
      count++;
    } else if (T != dynamic) {
      _items.removeWhere((key, value) {
        final remove = value is T;

        if (remove) {
          count++;
          if (dispose && value is Disposable) {
            value.dispose();
          }
        }

        return remove;
      });
    }

    return count;
  }

  /// Swaps [value] in Factory by given [key] or [Type].
  /// When given [key] is null, then key is [T] - check [ControlFactory.keyOf] for more info.
  ///
  /// Set [dispose] to dispose removed object/s.
  ///
  /// Basically calls [ControlFactory.remove] and [ControlFactory.set].
  void swap<T>({dynamic key, @required dynamic value, bool dispose: false}) {
    key = keyOf<T>(key: key, value: value);

    remove<T>(key: key, dispose: dispose);
    set<T>(key: key, value: value);
  }

  /// Removes initializer of given [key].
  /// Returns true if initializer is removed.
  bool removeInitializer(Type key) {
    return _initializers.remove(key) != null;
  }

  /// Swaps initializers in Factory.
  /// Basically calls [ControlFactory.removeInitializer] and [ControlFactory.setInitializer].
  void swapInitializer<T>(Initializer<T> initializer) {
    removeInitializer(T);
    setInitializer(initializer);
  }

  /// Checks if key/type/object is in Factory.
  bool contains(dynamic value) {
    if (containsKey(value)) {
      return true;
    }

    if (value is Type) {
      if (containsKey(value)) {
        return true;
      }

      //TODO: subtype
      if (_items.values.firstWhere((item) => item.runtimeType == value, orElse: () => null) != null || _initializers.keys.firstWhere((item) => item.runtimeType == value, orElse: () => null) != null) {
        return true;
      }
    }

    return _items.values.contains(value);
  }

  /// Checks if given [key] is in Factory.
  /// Looks to store and initializers.
  ///
  /// This function do not check subtypes!
  ///
  /// Returns true if [key] is found.
  bool containsKey(dynamic key) => _items.containsKey(key) || key is Type && _initializers.containsKey(key);

  /// Checks if Type is in Factory.
  /// Looks to store and initializers.
  ///
  /// This function do not check subtypes!
  ///
  /// Returns true if [Type] is found.
  bool containsType<T>() {
    for (final item in _items.values) {
      if (item.runtimeType == T) {
        return true;
      }
    }

    return _initializers.containsKey(T);
  }

  /// Clears whole Factory - all stored objects, initializers and injector.
  /// Also [BaseLocalization], [ControlBroadcast] and [ControlRoute] is removed and cleared/disposed.
  ///
  /// Call this function only if Factory re-init is required.
  /// After clear is possible to call [Control.initControl] again.
  ///
  /// Returns [true] if factory is cleared. [false] means, that factory is not initialized yet.
  bool clear() {
    if (!_initialized) {
      return false;
    }

    _items.forEach((key, value) {
      if (value is Disposable) {
        value.dispose();
      }
    });

    _items.clear();
    _initializers.clear();
    _initialized = false;
    _injector = null;

    return true;
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
  }
}

/// Mixin class for every [Disposable] object - mostly used with [ControlModel].
/// If object is initialized by [ControlFactory.get] then is stored into Factory.
/// Object is removed from factory on [dispose].
///
/// To prevent early remove set [preventDispose] or [preferSoftDispose] and then [dispose] object manually.
///
/// [factoryKey] represents [key] under which is object stored in [ControlFactory] - check [ControlFactory.keyOf] for more info about [key].
///
/// Use [ReferenceCounter] mixin to automatically count number of references and prevent early [dispose].
mixin LazyControl on Disposable {
  /// [key] under which is object stored in [ControlFactory].
  dynamic _factoryKey;

  /// [key] under which is object stored in [ControlFactory].
  /// Value of key is set by Factory - check [ControlFactory.keyOf] for more info about [key].
  dynamic get factoryKey => _factoryKey;

  @override
  void dispose() {
    super.dispose();

    Control.remove(key: factoryKey);
  }
}

/// Mixin class for [DisposeHandler] - mostly used with [ControlModel].
/// Counts references by [hashCode]. References are added/removed manually.
/// TODO: doc
mixin ReferenceCounter on DisposeHandler {
  final _references = new List<int>();

  @override
  bool get preferSoftDispose => _references.isNotEmpty;

  void addReference(Object object) {
    if (_references.contains(object.hashCode)) {
      return;
    }

    _references.add(object.hashCode);
  }

  void removeReference(Object object) => _references.remove(object.hashCode);
}
