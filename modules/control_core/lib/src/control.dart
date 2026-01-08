part of '../core.dart';

class _InvalidKey {}

/// A static service locator for managing dependencies and initializing objects within an application.
///
/// `Control` provides a centralized and easy-to-use API for dependency injection and service location,
/// abstracting the underlying `ControlFactory`. It is designed to be used as a static class,
/// meaning you will interact with it through its static methods like `Control.get<T>()`, `Control.set()`, etc.
///
/// Before using most of its features, the system must be initialized via `Control.initControl()`.
/// This setup phase registers dependencies, modules, and asynchronous startup tasks.
///
/// A typical initialization might look like this:
/// ```dart
/// Control.initControl(
///   entries: {
///     // Register a singleton instance.
///     HttpClient: HttpClient(),
///   },
///   factories: {
///     // Register a factory for creating new instances of a class.
///     // This is useful for objects that have a complex setup or are not singletons.
///     MyService: (args) => MyServiceImpl(),
///   },
///   modules: [
///     // Add pre-built or custom modules for features like routing, localization, etc.
///     RoutingModule(),
///   ],
///   initAsync: () async {
///     // Perform any asynchronous setup.
///     // This is a good place to load settings from storage or initialize services.
///     await Settings.load();
///   },
/// );
/// ```
///
/// Once initialized, you can retrieve dependencies from anywhere in your app:
/// ```dart
/// final myService = Control.get<MyService>();
/// myService.doSomething();
/// ```
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

  /// Initializes the main `ControlFactory` with dependencies, modules, and configurations.
  ///
  /// This function must be called before any other `Control` methods are used.
  /// It sets up the entire dependency injection system for the application.
  ///
  /// - [debug]: Sets the runtime debug mode. Defaults to [kDebugMode].
  /// - [entries]: A map of objects to be registered as singletons.
  ///   These objects are immediately available for retrieval via `Control.get()`.
  /// - [factories]: A map of factory functions (`InitFactory`) for lazy initialization of objects.
  ///   A new object is created when `Control.get()` or `Control.init()` is called for the first time for a given type.
  /// - [modules]: A list of `ControlModule`s that bundle entries, factories, and initialization logic.
  ///   This is a convenient way to organize features.
  /// - [initModules]: An optional asynchronous function to perform custom initialization of loaded modules.
  /// - [initAsync]: An optional asynchronous function for custom initialization logic,
  ///   such as loading settings, warming up caches, or connecting to services.
  ///
  /// Returns `true` if initialization was successful, or `false` if the control system was already initialized.
  static bool initControl({
    bool? debug,
    Map? entries,
    Map<Type, InitFactory>? factories,
    List<ControlModule> modules = const [],
    Future Function(List<ControlModule> modules)? initModules,
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
        ]);

        await initModules?.call(modules);

        await initAsync?.call();
      },
    );

    return true;
  }

  /// Retrieves an object of type [T] from the `ControlFactory`.
  ///
  /// This is the primary method for accessing your application's dependencies.
  ///
  /// - [key]: An optional key to distinguish between multiple objects of the same type.
  ///   If not provided, the type [T] is used as the key.
  /// - [args]: Optional arguments to pass to the object's `init` method if it is being created for the first time.
  ///   This is only applicable for objects that implement `Initializable`.
  /// - [withInjector]: This parameter is currently unused and will be removed in a future version.
  ///
  /// If the requested object is not already in the factory's store, `get` will attempt to create it
  /// using a registered `InitFactory`. If the created object is a `LazyControl`, it will be stored
  /// for future retrievals.
  ///
  /// Example:
  /// ```dart
  /// // Retrieve a service by its type.
  /// final myService = Control.get<MyService>();
  ///
  /// // Retrieve an object by a custom key.
  /// final specialConfig = Control.get<Config>(key: 'special_config');
  /// ```
  ///
  /// Returns the requested object, or `null` if it cannot be found or created.
  static T? get<T>({dynamic key, dynamic args, bool withInjector = true}) =>
      factory.get<T>(key: key, args: args, withInjector: withInjector);

  /// Asynchronously retrieves an object of type [T].
  ///
  /// This method is a convenience wrapper around [get]. While the underlying operation is synchronous,
  /// this method returns a `Future`, which can be useful in async contexts to maintain a consistent
  /// method signature.
  ///
  /// See [get] for more details on parameters.
  ///
  /// Returns a `Future` that completes with the requested object, or `null`.
  static Future<T?> getAsync<T>(
          {dynamic key, dynamic args, bool withInjector = true}) async =>
      get<T>(key: key, args: args, withInjector: withInjector);

  /// Stores a [value] with a given [key] in the `ControlFactory`.
  ///
  /// This is useful for programmatically adding singleton instances to the factory at runtime.
  /// If an object with the same key already exists, it will be overridden.
  ///
  /// - [key]: An optional key for storing the value. If `null`, the key is inferred from the
  ///   generic type `T` or the runtime type of the [value]. See `ControlFactory.keyOf` for details.
  /// - [value]: The object instance to store.
  ///
  /// Returns the key under which the value was stored.
  static dynamic set<T>({dynamic key, required T value}) =>
      factory.set<T>(key: key, value: value);

  /// Registers a factory function ([InitFactory]) for a given type [T].
  ///
  /// This allows for lazy initialization of objects. The factory function will be invoked
  /// the first time an object of type [T] is requested via `Control.get()` or `Control.init()`.
  ///
  /// - [key]: An optional key for the factory. This should be a `Type`. If `null`, the type [T] is used as the key.
  /// - [init]: The factory function that creates an instance of [T]. It receives optional arguments.
  ///
  /// Returns the key under which the factory was stored.
  static dynamic add<T>({dynamic key, required InitFactory<T> init}) =>
      factory.add<T>(key: key, init: init);

  /// Creates a new instance of an object of type [T] using a registered factory.
  ///
  /// Unlike `get`, this method *always* creates a new instance and does not store it in the factory.
  ///
  /// - [key]: The type key for the factory to use. If `null`, the type [T] is used.
  /// - [args]: Optional arguments to pass to the object's `init` method if it implements `Initializable`.
  ///
  /// Returns a new object of type [T], or `null` if no corresponding factory is found.
  static T? init<T>({Type? key, dynamic args}) =>
      factory.init(key: key, args: args);

  /// Retrieves an object of type [T] only if it has already been instantiated and stored in the factory.
  ///
  /// This method will not attempt to create a new instance if one is not found.
  ///
  /// - [key]: An optional key to look up the object. If `null`, the type [T] is used.
  ///
  /// Returns the existing object, or `null` if it is not in the factory's store.
  static T? maybe<T>({dynamic key}) {
    if (!factory.containsItem<T>(key: key)) {
      return null;
    }

    return factory.get<T>(key: key);
  }

  /// Retrieves an object of type [T], or creates and stores a default one if it doesn't exist.
  ///
  /// This is a convenient "get or create" method.
  ///
  /// - [key]: The key to look up the object.
  /// - [args]: Arguments to pass if a new object is created from a factory (via `get`).
  /// - [value]: A function that returns a new instance of [T] if the object is not found in the factory.
  /// - [store]: If `true` (the default), the newly created object from [value] will be stored in the factory for future use.
  ///
  /// Returns an existing or newly created object of type [T].
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

  /// Attempts to resolve and retrieve an object of type [T] from a sequence of sources.
  ///
  /// The resolution order is:
  /// 1. From the [source] object itself (e.g., a `Map` or other data structure, parsed via `Parse.getArg`).
  /// 2. From the `ControlFactory` using `Control.get()`.
  /// 3. From the [defaultValue] function, if provided.
  ///
  /// - [source]: The primary source to check for the object.
  /// - [key]: The key to use for lookup in both [source] and the factory.
  /// - [args]: Arguments to pass to `init` if a new object is created.
  /// - [defaultValue]: A function that provides a fallback object if resolution fails.
  ///
  /// Returns the resolved object, or `null` if it cannot be found in any source.
  static T? resolve<T>(dynamic source,
          {dynamic key, dynamic args, T? Function()? defaultValue}) =>
      factory.resolve<T>(source,
          key: key, args: args, defaultValue: defaultValue);

  /// Evaluates a dynamic object and executes a callback with the resolved value.
  ///
  /// This method handles different types of objects:
  /// - If [object] is a `Type`, it retrieves the corresponding instance from `Control.get()`.
  /// - If [object] is a `Function`, it calls the function and uses its return value.
  /// - If [object] is a `Future`, it awaits the future and uses its result.
  /// - For any other type, it uses the [object] directly.
  ///
  /// The resolved value is then passed to the [callback].
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

  /// Removes an object or a group of objects from the `ControlFactory`.
  ///
  /// - [key]: The key of the object to remove. If `null`, the type [T] is used as the key.
  /// - [dispose]: If `true`, the `dispose` method will be called on the removed object if it is `Disposable`.
  ///
  /// If an object with the exact [key] is not found, this method will remove all stored instances that are of type [T].
  ///
  /// Returns the number of items that were removed.
  static int remove<T>({dynamic key, bool dispose = false}) =>
      factory.remove<T>(key: key, dispose: dispose);
}

/// The core implementation of the service locator and dependency injection container.
///
/// `ControlFactory` manages the lifecycle of objects, including their registration,
/// creation (through factories), retrieval, and disposal.
///
/// While you can create and manage your own `ControlFactory` instances, most applications
/// will use the default global instance accessible via `Control.factory`.
///
/// The factory stores objects in two main ways:
/// - As singleton instances (`_items`): These are created once and reused.
/// - As factory functions (`_factory`): These are functions that know how to create a new instance of an object when needed.
///
/// The factory is initialized via the `initialize` method, which is typically called by `Control.initControl`.
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
  bool get isInitialized => _initialized && _completer.isCompleted;

  /// Runtime debug value. Default value is [false].
  bool debug = false;

  /// Completer for factory initialization.
  /// Use [onReady] to listen this completer.
  Completer _completer = Completer();

  /// Callable class - [get].
  T? call<T>({dynamic key, dynamic args, bool withInjector = true}) =>
      get<T>(key: key, args: args, withInjector: withInjector);

  /// A future that completes when the factory has finished its asynchronous initialization.
  ///
  /// If `initAsync` was provided to `Control.initControl` or `initialize`, this future
  /// will complete after `initAsync` has finished. If the factory is already initialized,
  /// the future completes immediately.
  ///
  /// This is useful to ensure that all services are ready before starting the application logic.
  ///
  /// ```dart
  /// await Control.factory.onReady();
  /// runApp(MyApp());
  /// ```
  Future<void> onReady() async {
    if (_completer.isCompleted) {
      return;
    }

    return _completer.future;
  }

  /// Initializes the factory with a set of entries, factories, and an optional async setup task.
  ///
  /// This method is called by `Control.initControl` and should generally not be called directly
  /// unless you are managing your own `ControlFactory` instance.
  ///
  /// - [entries]: A map of singleton objects to be added to the factory's store.
  /// - [factories]: A map of `InitFactory` functions for lazy object creation.
  /// - [initAsync]: An asynchronous function to execute as the final step of initialization.
  ///
  /// Returns `true` if initialization was successful, or `false` if the factory was already initialized.
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

    _completer.complete();
  }

  /// Loads module into this factory.
  ///
  /// Check [Control.initControl] - Modules are typically given to factory as soon as possible.
  void registerModule(ControlModule module, {bool includeSubModules = false}) =>
      module.initStore(this, includeSubModules: includeSubModules);

  /// Determines the key to use for storing or retrieving an object in the factory.
  ///
  /// The key is resolved with the following priority:
  /// 1. The provided [key] argument, if it's not `null`.
  /// 2. The generic type `T`, if it's not `dynamic`.
  /// 3. The runtime type of the `value` object, if provided.
  ///
  /// This logic allows for flexible registration and retrieval of dependencies.
  ///
  /// Returns the resolved key.
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

  /// Retrieves an object of type [T] from the factory.
  ///
  /// This is the core method for accessing dependencies.
  ///
  /// - [key]: An optional key. If not provided, the type `T` is used.
  /// - [args]: Optional arguments for `Initializable` objects.
  ///
  /// When an object is requested:
  /// 1. The factory first checks its internal store (`_items`) for an existing instance.
  /// 2. If found, it's returned. If `args` are provided, the object's `init` method is called.
  /// 3. If not found, the factory looks for a registered `InitFactory` to create a new instance.
  /// 4. If the newly created object is a `LazyControl`, it's stored for future requests.
  ///
  /// Returns the requested object, or `null` if it cannot be found or created.
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

  /// Creates a new instance of an object of type [T] using a registered factory.
  ///
  /// This method always creates a new instance and does not store it, unless the object
  /// itself is a `LazyControl` that gets stored by the `get` method which calls `init`.
  ///
  /// This is primarily used internally by `get` but can be used to explicitly create new objects.
  ///
  /// - [key]: The type key for the factory. Defaults to `T`.
  /// - [args]: Arguments for `Initializable` objects.
  ///
  /// Returns a new object of type [T], or `null` if no factory is found.
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

  /// Finds and returns a registered [InitFactory] for a given type.
  ///
  /// The lookup order is:
  /// 1. By the provided [key].
  /// 2. By the generic type `T`.
  /// 3. By checking if any registered factory key is a subtype of `T`.
  ///
  /// Used by `init` to get the correct factory function for object creation.
  ///
  /// Returns the `InitFactory`, or `null` if not found.
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

/// Provides static access to the default `ControlBroadcast` instance.
///
/// This class acts as a convenient, global event bus for the application, allowing different
/// parts of the app to communicate without direct dependencies.
///
/// It supports two types of broadcasting:
/// - **Object Broadcasting**: Sending a data object to interested listeners.
/// - **Event Broadcasting**: Sending a simple notification without data.
///
/// Example:
/// ```dart
/// // Somewhere in your app, a user logs in.
/// BroadcastProvider.broadcast<User>(key: 'user_changed', value: user);
///
/// // In a UI widget, listen for user changes to rebuild.
/// BroadcastProvider.subscribe<User>('user_changed', (user) {
///   setState(() {
///     _userName = user.name;
///   });
/// });
/// ```
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

/// A mixin that automatically handles the removal of an object from the `ControlFactory` when it is disposed.
///
/// This is particularly useful for objects with a managed lifecycle, such as `ControlModel`s in UI components.
/// When an object with this mixin is created via `Control.get()`, it is stored in the factory.
/// When its `dispose()` method is called, it automatically removes itself from the factory.
///
/// - The [factoryKey] is the key under which the object is stored. It is automatically assigned by the factory.
///
/// To prevent the object from being disposed prematurely (e.g., when it is shared across multiple widgets),
/// you can use this mixin in combination with `ReferenceCounter`.
///
/// Example:
/// ```dart
/// class MyModel extends ControlModel with LazyControl {
///   // ... model logic ...
/// }
///
/// // In a widget, get the model. It will be stored in the factory.
/// final model = Control.get<MyModel>();
///
/// // When the widget is disposed, if it also disposes the model,
/// // the model will be removed from the factory.
/// ```
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

/// A mixin that delays a piece of initialization logic until the main `ControlFactory` is fully initialized.
///
/// This is useful for `Initializable` objects that depend on services that are registered
/// asynchronously during `Control.initControl`.
///
/// When an object with this mixin is initialized via its `init` method, it waits for `Control.factory.onReady()`
/// to complete and then calls the `onLateInit()` method.
///
/// Example:
/// ```dart
/// class MyService with Initializable, LateInit {
///   late final ApiService _api;
///
///   @override
///   void onLateInit() {
///     // This code runs after the factory is fully ready.
///     _api = Control.get<ApiService>();
///     print('ApiService is now available!');
///   }
/// }
/// ```
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
