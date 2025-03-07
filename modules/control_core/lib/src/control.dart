part of '../core.dart';

class _InvalidKey {}

/// Service Locator with Factory and object Initialization.
/// Start with [Control.initControl] to initialize [ControlFactory].
class Control {
  /// Control is pure static class.
  /// Just hidden constructor.
  Control._();

  /// Creates new standalone instance of Control Factory.
  static ControlFactory newFactory() => ControlFactory._();

  /// Instance of Main Factory.
  static final ControlFactory _instance = ControlFactory._();

  /// Returns instance of [ControlFactory].
  static ControlFactory get factory => _instance;

  /// Checks if [ControlFactory] is initialized.
  ///
  /// Factory can be initialized with [Control.initControl].
  static bool get isInitialized => factory.isInitialized;

  /// Internal debug mark.
  static bool get debug => factory.debug;

  /// Returns default instance of [ControlBroadcast] - this instance is stored in [ControlFactory].
  /// Use [BroadcastProvider] for base broadcast operations.
  static ControlBroadcast get broadcast => factory._broadcast;

  /////
  /////
  /////

  /// Initializes instance of [ControlFactory].
  ///
  /// [debug] - Runtime debug value. Default value is [kDebugMode].
  /// [entries] - Default items to store in [ControlFactory]. Use [Control.get] to retrieve this objects and [Control.set] to add new ones.
  ///           - For Entry objects, if models, [DisposeHandler.preferSoftDispose] is checked to prevent dispose of these object.
  /// [factories] - Default factory initializers to store in [ControlFactory] Use [Control.init] or [Control.get] to retrieve concrete objects.
  /// [modules] - Custom or prebuild [ControlModule]s, like Localino, Prefs, Routing, etc.
  /// [initAsync] - Custom [async] function to execute during [ControlFactory] initialization. Don't overwhelm this function - it's just for loading core settings.
  ///
  /// Returns `true` if initialization success.
  static bool initControl({
    bool? debug,
    Map? entries,
    Map<Type, InitFactory>? factories,
    List<ControlModule> modules = const [],
    Future Function()? initAsync,
  }) {
    if (isInitialized) {
      return false;
    }

    factory.debug = debug ?? kDebugMode;

    entries ??= {};
    factories ??= {};

    modules = ControlModule.fillModules(modules);

    factory.initialize(
      entries: {
        for (ControlModule module in modules) ...module.entries,
        ...entries,
      },
      factories: {
        for (ControlModule module in modules) ...module.factories,
        ...factories,
      },
      initAsync: () async {
        for (ControlModule module in modules) {
          if (module.preInit) {
            await module.init();
          }
        }

        await FutureBlock.wait([
          for (ControlModule module in modules)
            if (!module.preInit) module.init(),
          initAsync?.call(),
        ]);
      },
    );

    return true;
  }

  /////
  /////
  /////

  /// Returns object of requested type by given [key] or by [Type] from [ControlFactory].
  /// Given [args] are passed to [Initializable.init] if new instance of object is constructed.
  ///
  /// If object is not found in internal store, then factory tries to initialize new one via [ControlFactory.init].
  /// When initialized object is [LazyControl] then this object is stored into Factory.
  ///
  /// Returns concrete object or null.
  static T? get<T>({dynamic key, dynamic args, bool withInjector = true}) =>
      factory.get<T>(key: key, args: args, withInjector: withInjector);

  /// Stores [value] with given [key] in [ControlFactory]. When given [key] is null, then key is [T] or generated from [Type] of given [value] - check [ControlFactory.keyOf] for more info.
  /// Object with same [key] previously stored in factory is overridden.
  /// Returns [key] of the stored [value].
  static dynamic set<T>({dynamic key, required T value}) =>
      factory.set<T>(key: key, value: value);

  /// Adds Factory for later use - [Control.init] or [Control.get].
  static dynamic add<T>({dynamic key, required InitFactory<T> init}) =>
      factory.add<T>(key: key, init: init);

  /// Returns new object of requested type by given [key] or by [Type] from [ControlFactory].
  /// Given [args] are passed to [Initializable.init].
  ///
  /// Returns concrete object or null.
  static T? init<T>({Type? key, dynamic args}) =>
      factory.init(key: key, args: args);

  /// Returns object of requested type by given [key] or by [Type] from [ControlFactory].
  /// BUT only if object is found in internal store
  ///
  /// Returns concrete object or null.
  static T? maybe<T>({dynamic key}) {
    if (!factory.containsItem<T>(key: key)) {
      return null;
    }

    return factory.get<T>(key: key);
  }

  /// Returns object of requested type by given [key] or by [Type] from [ControlFactory].
  /// If object is not found, then [value] is used.
  /// When [value] is used and [store] is set, then [value] will be stored into [ControlFactory] for future lookups.
  ///
  /// Check [get] and [set] functions.
  static T use<T>(
      {dynamic key,
      dynamic args,
      required T Function() value,
      bool store = true}) {
    final object = get<T>(key: key, args: args);

    if (object != null) {
      return object;
    }

    final newObject = value();

    if (store) {
      set<T>(key: key, value: newObject);
    }

    return newObject;
  }

  /// Executes sequence of functions to retrieve expected object.
  /// Look up in [source] for item via [Parse.getArg] and if object is not found then [ControlFactory.get] is executed. After all, [defaultValue] is used.
  /// Returns object from [source] then [ControlFactory] then [defaultValue].
  static T? resolve<T>(dynamic source,
          {dynamic key, dynamic args, T? Function()? defaultValue}) =>
      factory.resolve<T>(source,
          key: key, args: args, defaultValue: defaultValue);

  /// Executes proper function based on object type, then retrieve result via [callback].
  /// Type - get object from [ControlFactory]
  /// Function - call given function
  /// Future - waits to complete
  static void evaluate(dynamic object, ValueCallback callback) async {
    if (object is Type) {
      if (!Control.isInitialized && !Control.factory.containsKey(object)) {
        await Control.factory.onReady();
      }

      callback.call(Control.get(key: object));
      return;
    }

    if (object is Function) {
      callback.call(object.call());
      return;
    }

    if (object is Future) {
      callback.call(await object);
      return;
    }

    callback.call(object);
  }

  /// Removes specific object with given [key] or by [Type] from [ControlFactory].
  /// If object of given [key] is not found, then all instances of [T] are removed.
  /// Set [dispose] to dispose removed object.
  ///
  /// Returns number of removed items.
  static int remove<T>({dynamic key, bool dispose = false}) =>
      factory.remove<T>(key: key, dispose: dispose);
}

/// Service Locator with Factory and object Initialization.
class ControlFactory with Disposable {
  /// Just private constructor.
  ControlFactory._();

  /// Stored objects in Factory.
  /// [key] is dynamic and is determined by [keyOf].
  /// [value] is actual object.
  final _items = {};

  /// Stored Initializers for object construction.
  /// [key] is [Type] - typically interface.
  /// [value] is [InitFactory] that constructs a concrete object.
  final _factory = <Type, InitFactory>{};

  /// Instance of default [ControlBroadcast].
  final _broadcast = ControlBroadcast();

  /// Factory initialize state.
  bool _initialized = false;

  /// Checks if Factory is initialized.
  /// Use [onReady] to listen [initialize] completion.
  ///
  /// Returns `true` if Factory is initialized, including [initAsync].
  bool get isInitialized => _initialized && _completer == null;

  /// Runtime debug value. Default value is [false].
  bool debug = false;

  /// Completer for factory initialization.
  /// Use [onReady] to listen this completer.
  Completer? _completer = Completer();

  /// Callable class - [get].
  T? call<T>({dynamic key, dynamic args, bool withInjector = true}) =>
      get<T>(key: key, args: args, withInjector: withInjector);

  /// Completes when Factory is initialized including [initAsync].
  ///
  /// Returns [Future] of init [Completer].
  Future<void>? onReady() async => _completer?.future;

  /// Initialization of this factory.
  /// This function should be called first before any use of factory store.
  ///
  /// [entries] - Default items to store in [ControlFactory]. Use [Control.get] to retrieve this objects and [Control.set] to add new ones.
  ///           - For Entry objects, if models, [DisposeHandler.preferSoftDispose] is checked to prevent dispose of these object.
  /// [factories] - Default factory initializers to store in [ControlFactory] Use [Control.init] or [Control.get] to retrieve concrete objects.
  /// [modules] - Custom or prebuild [ControlModule]s, like Localino, Prefs, Routing, etc.
  /// [initAsync] - Custom [async] function to execute during [ControlFactory] initialization. Don't overwhelm this function - it's just for loading core settings.
  ///
  /// Returns `true` if initialization success.
  bool initialize(
      {Map? entries,
      Map<Type, InitFactory>? factories,
      Future Function()? initAsync}) {
    if (_initialized) {
      return false;
    }

    _initialized = true;

    _items[ControlFactory] = this;
    _items[ControlBroadcast] = _broadcast;

    if (entries != null) {
      _items.addAll(entries);
    }

    if (factories != null) {
      _factory.addAll(factories);
    }

    _items.forEach((key, value) {
      if (value is Initializable) {
        _init(value, args: {});

        printDebug('Factory init $key - ${value.runtimeType.toString()}');
      }

      if (value is DisposeHandler) {
        value.preferSoftDispose = true;

        printDebug(
            'Factory prefers soft dispose of $key - ${value.runtimeType.toString()}');
      }
    });

    _initializeAsync(initAsync);

    return true;
  }

  /// Handle [async] load from [initialize] and then finishes init [Completer].
  Future<void> _initializeAsync(Future Function()? initAsync) async {
    if (initAsync != null) {
      await initAsync();
    }

    _completer!.complete();
    _completer = null;
  }

  /// Loads module into this factory.
  ///
  /// Check [Control.initControl] - Modules are typically given to factory as soon as possible.
  void registerModule(ControlModule module, {bool includeSubModules = false}) =>
      module.initStore(this, includeSubModules: includeSubModules);

  /// Resolve [key] for given args.
  ///
  /// Priority:
  /// [key] - actual raw key.
  /// [T] - generic type (dynamic is ignored).
  /// [value] - runtime type of given object.
  ///
  /// Returns actual factory [key].
  dynamic keyOf<T>({dynamic key, dynamic value}) =>
      key ??= T != dynamic ? T : value?.runtimeType;

  /// Adds Factory for later use - [Control.init] or [Control.get].
  void add<T>({Type? key, required InitFactory<T> init}) {
    key ??= T;

    assert(() {
      if (_factory.containsKey(key)) {
        printDebug(
            'Factory already contains key: $key. Value of this key will be override.');
      }
      return true;
    }());

    _factory[key] = init;
  }

  /// Stores [value] with given [key] in [ControlFactory]. When given [key] is null, then key is [T] or generated from [Type] of given [value] - check [ControlFactory.keyOf] for more info.
  /// Object with same [key] previously stored in factory is overridden.
  /// Returns [key] of the stored [value].
  dynamic set<T>({dynamic key, required dynamic value}) {
    key = keyOf<T>(key: key, value: value);

    assert(key != null);
    assert(() {
      if (_items.containsKey(key) && _items[key] != value) {
        printDebug(
            'Factory already contains key: ${key.toString()}. Value of this key will be override.');
      }
      return true;
    }());

    _items[key] = value;

    return key;
  }

  /// Returns object of requested type by given [key] or by [Type] from [ControlFactory].
  /// Given [args] are passed to [Initializable.init] if new instance of object is constructed. New instances always call [Initializable.init], if implements.
  /// When factory already contains requested object, [Initializable.init] is called only when [args] are set.
  ///
  /// If object is not found in internal store, then factory tries to initialize new one via [ControlFactory.init].
  /// When initialized object is [LazyControl] then this object is stored into Factory.
  ///
  /// Returns concrete object or null.
  T? get<T>({dynamic key, dynamic args, bool withInjector = true}) {
    final useExactKey = key != null;
    key = keyOf<T>(key: key);

    assert(key != null);

    if (_items.containsKey(key)) {
      final item = _items[key] as T;

      if (item != null) {
        _init(
          item,
          args: args,
          forceInit: false,
        );

        return item;
      }
    }

    if (!useExactKey) {
      T? item;

      if (T != dynamic) {
        item =
            _items.values.firstWhere((item) => item is T, orElse: () => null);
      } else if (key == Type) {
        item = _items.values
            .firstWhere((item) => item.runtimeType == key, orElse: () => null);
      }

      if (item != null) {
        _init(
          item,
          args: args,
          forceInit: false,
        );

        return item;
      }
    }

    final item = init<T>(
      key: (useExactKey && key is Type) ? key : null,
      args: args,
      forceInit: true,
    );

    if (item is LazyControl) {
      if (item.factoryKey != null) {
        key = item.factoryKey;
      } else {
        item._factoryKey = key;
      }

      set<T>(key: key, value: item);
    }

    return item;
  }

  /// Inits [Initializable] [item] with given [args].
  /// Set [forceInit] to init with empty args.
  void _init<T>(dynamic item, {dynamic args, bool forceInit = true}) {
    if (item is Initializable && (args != null || forceInit)) {
      item.init(args is Map ? args : ControlArgs.of(args).data);
    }
  }

  /// Returns new object of requested type by given [key] or by [Type] from [ControlFactory].
  /// Given [args] are passed to [Initializable.init], if implements.
  /// Set [forceInit] to prevent initialization when [args] are not given.
  ///
  /// This function is also called when [ControlFactory.get] fails to find object in internal store.
  /// In most of cases is preferred to use more powerful [ControlFactory.get].
  T? init<T>({Type? key, dynamic args, bool forceInit = true}) {
    final initializer = findInitializer<T>(key);

    if (initializer != null) {
      final item = initializer(args);

      _init<T>(item, args: args, forceInit: forceInit);

      return item;
    }

    return null;
  }

  /// Executes sequence of functions to retrieve expected object.
  /// Look up in [source] for item via [Parse.getArg] and if object is not found then [ControlFactory.get] is executed. After all, [defaultValue] is used.
  /// Returns object from [source] then [ControlFactory] then [defaultValue].
  T? resolve<T>(dynamic source,
      {dynamic key, dynamic args, T? Function()? defaultValue}) {
    final item = Parse.getArg<T>(source, key: key);
    args = (ControlArgs.of(source)..set(args)).data;

    if (item != null) {
      _init(item, args: args, forceInit: false);
      return item;
    }

    return get<T>(key: key, args: args) ?? defaultValue?.call();
  }

  /// Finds and returns [InitFactory] of given [Type].
  ///
  /// [ControlFactory.init] uses this method to retrieve [InitFactory].
  ///
  /// nullable
  InitFactory<T?>? findInitializer<T>([Type? key]) {
    if (key != null && _factory.containsKey(key)) {
      return _factory[key] as InitFactory<T?>;
    } else if (_factory.containsKey(T)) {
      return _factory[T] as InitFactory<T?>;
    } else if (T != dynamic) {
      final key = _factory.keys
          .firstWhere((item) => item is T, orElse: () => _InvalidKey);

      if (key != _InvalidKey) {
        return _factory[key] as InitFactory<T?>;
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
  int remove<T>({dynamic key, bool dispose = false}) {
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
  void swap<T>({dynamic key, required dynamic value, bool dispose = false}) {
    key = keyOf<T>(key: key, value: value);

    remove<T>(key: key, dispose: dispose);
    set<T>(key: key, value: value);
  }

  /// Removes initializer of given [key].
  /// Returns true if initializer is removed.
  bool removeInitializer(Type key) {
    return _factory.remove(key) != null;
  }

  /// Swaps initializers in Factory.
  /// Basically calls [ControlFactory.removeInitializer] and [ControlFactory.add].
  void swapInitializer<T>(InitFactory<T> initializer) {
    removeInitializer(T);
    add<T>(init: initializer);
  }

  /// Checks if key/type/object is in Factory.
  bool contains(dynamic value) {
    if (containsKey(value)) {
      return true;
    }

    if (value is Type) {
      //TODO: subtype
      if (_items.values.any((item) => item.runtimeType == value) ||
          _factory.keys.any((item) => item.runtimeType == value)) {
        return true;
      }
    }

    return _items.values.contains(value);
  }

  /// Checks if given [key] is in Factory.
  /// Looks to store and factories.
  ///
  /// This function do not check subtypes!
  ///
  /// Returns true if [key] is found.
  bool containsKey(dynamic key) =>
      _items.containsKey(key) || (key is Type && _factory.containsKey(key));

  /// Checks if given [key] is already initialized in Factory.
  /// Looks just to store. (factories are not included)
  ///
  /// This function do not check subtypes!
  ///
  /// Returns true if [key] is found.
  bool containsItem<T>({dynamic key}) => _items.containsKey(keyOf<T>(key: key));

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

    return _factory.containsKey(T);
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

    _initialized = false;
    _completer = Completer();

    _items.forEach((key, value) {
      if (value is Disposable) {
        value.dispose();
      }
    });

    _items.clear();
    _factory.clear();
    _initialized = false;

    return true;
  }

  void printDebugStore({bool items = true, bool initializers = true}) {
    if (items) {
      printDebug('--- Items ---');
      _items.forEach((key, value) => value == this
          ? printDebug(
              '$runtimeType - $isInitialized | ${_items.length} | ${_factory.length} | $hashCode')
          : printDebug('$key - $value'));
    }

    if (initializers) {
      printDebug('--- Initializers ---');
      _factory.forEach((key, value) => printDebug('$key - $value'));
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('--- $runtimeType --- $isInitialized --- $hashCode');
    buffer.writeln('--- Items --- ${_items.length}');
    buffer.writeln('--- Initializers --- ${_factory.length}');

    return buffer.toString();
  }

  @override
  void dispose() {
    clear();
  }
}

/// Provider of [ControlBroadcast].
///
/// Global stream to broadcast data and events.
/// Stream is driven by keys and object types.
///
/// Default broadcast is created with [ControlFactory] and is possible to use it via [BroadcastProvider].
class BroadcastProvider {
  /// Subscribe to global object stream for given [key] and [Type].
  /// [onData] callback is triggered when [broadcast] with specified [key] and correct [value] is called.
  /// [current] when object for given [key] is stored from previous [broadcast], then [onData] is notified immediately.
  ///
  /// Returns [BroadcastSubscription] to control and close subscription.
  static BroadcastSubscription<T> subscribe<T>(
          dynamic key, ValueChanged<T?> onData) =>
      Control.broadcast.subscribeTo<T>(key, onData);

  /// Subscribe to global event stream for given [key].
  /// [callback] is triggered when [broadcast] or [broadcastEvent] with specified [key] is called.
  ///
  /// Returns [BroadcastSubscription] to control and close subscription.
  static BroadcastSubscription subscribeEvent(
          dynamic key, VoidCallback callback) =>
      Control.broadcast.subscribeEvent(key, callback);

  /// Sends [value] to global object stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores [value] for future subs and notifies them immediately after [subscribe].
  ///
  /// Returns number of notified subs.
  static void broadcast<T>({dynamic key, dynamic value, bool store = false}) =>
      Control.broadcast.broadcast<T>(key: key, value: value, store: store);

  /// Sends event to global event stream.
  /// Subs with same [key] will be notified.
  ///
  /// Returns number of notified subs.
  static void broadcastEvent<T>({dynamic key}) =>
      Control.broadcast.broadcastEvent<T>(key: key);
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

mixin LateInit on Initializable {
  bool? _ready;

  bool get isInitReady => _ready ?? false;

  @override
  void init(Map args) {
    super.init(args);

    _onReady();
  }

  void _onReady() async {
    if (_ready != null) {
      return;
    }

    _ready = false;

    await Control.factory.onReady();

    _ready = true;

    onLateInit();
  }

  void onLateInit();
}
