part of '../core.dart';

/// Defines a modular unit for organizing and registering dependencies within the control system.
///
/// A `ControlModule` is a powerful way to group related dependencies (both singleton instances and factories)
/// and initialization logic. This is especially useful for feature-based organization of your application.
///
/// Each module can define:
/// - `entries`: A map of singleton instances to be registered with the `ControlFactory`.
/// - `factories`: A map of factory functions for lazy object creation.
/// - `init`: An asynchronous initialization method that is called by `Control.initControl`.
/// - `priority`: An integer that determines the initialization order. Higher priority modules are initialized first.
/// - `subModules`: Other `ControlModule`s that this module depends on.
///
/// Modules are passed to `Control.initControl` and are automatically processed.
///
/// Example:
/// ```dart
/// class ApiModule extends ControlModule<ApiService> {
///   @override
///   Map<Type, InitFactory> get factories => {
///     ApiService: (args) => ApiServiceImpl(),
///   };
///
///   @override
///   Future<void> init() async {
///     // The module instance is created and available here.
///     module = Control.get<ApiService>();
///     await module!.connect();
///   }
/// }
///
/// // In your main setup:
/// Control.initControl(modules: [ApiModule()]);
/// ```
abstract class ControlModule<T> implements Comparable<ControlModule> {
  /// The primary type key for this module.
  ///
  /// By default, this is the generic type `T`. It's used to identify the module
  /// and its primary provided object within the `ControlFactory`.
  Type get key => T;

  /// The instance of the main object provided by this module.
  ///
  /// This is typically initialized within the `init` method after being retrieved
  /// from the `ControlFactory`.
  T? module;

  /// The initialization priority of the module.
  ///
  /// Modules with a higher priority value are initialized first.
  /// A priority greater than 0 also marks the module for `pre-initialization`,
  /// meaning its `init` method is awaited before other non-pre-init modules.
  int priority = -1;

  /// A map of singleton instances to be registered in the `ControlFactory`.
  ///
  /// The key is typically a `Type`, and the value is the object instance.
  /// By default, it registers the `module` instance under its `key`.
  Map get entries => {key: module};

  /// A map of factory functions for lazy object creation, to be registered in the `ControlFactory`.
  ///
  /// The key is the `Type` to be requested, and the value is an `InitFactory`
  /// that creates an instance of that type.
  Map<Type, InitFactory> get factories => {};

  /// If `true`, the module's `init()` method is awaited before other modules begin their initialization.
  ///
  /// This is determined by `priority > 0`. It's useful for modules that provide
  /// foundational services needed by other modules.
  bool get preInit => priority > 0;

  /// Returns `true` if the module's primary object (`module`) has been instantiated.
  bool get isInitialized => module != null;

  /// A map of other `ControlModule` types that this module depends on.
  ///
  /// The control system will automatically discover and include these sub-modules
  /// during initialization, ensuring that all dependencies are available.
  Map<Type, InitFactory> get subModules => {};

  static bool initControl(ControlModule module, {Map? args, bool? debug}) =>
      Control.initControl(
        debug: debug ?? true,
        modules: [
          ...module.getInactiveSubmodules(Control.factory, args: args),
          module,
        ],
      );

  static List<ControlModule> fillModules(List<ControlModule> modules) {
    modules = _fillModules(modules);
    modules.sort();

    return modules;
  }

  static List<ControlModule> _fillModules(List<ControlModule> modules) {
    final output = List.of(modules);

    for (final element in modules) {
      element.subModules.forEach((key, value) {
        if (!output.any((element) => element.key == key)) {
          output.addAll(_fillModules([value.call(null)]));
        }
      });
    }

    return output;
  }

  /// Initializes the `module` field by retrieving it from the `ControlFactory`.
  ///
  /// This should be called after the factory has been initialized. It's often
  /// used within the `init` method.
  void initModule() {
    if (Control.isInitialized) {
      module = Control.get<T>(key: key);
    }
  }

  /// Manually registers the module's `entries` and `factories` into a given `ControlFactory`.
  ///
  /// This is typically handled automatically by `Control.initControl`.
  ///
  /// - [factory]: The `ControlFactory` to register with.
  /// - [includeSubModules]: If `true`, all sub-modules will also be registered.
  void initStore(ControlFactory factory, {bool includeSubModules = false}) {
    _initModuleStore(factory, this);

    if (includeSubModules) {
      getInactiveSubmodules(factory).forEach((element) {
        _initModuleStore(factory, element);
      });
    }
  }

  static void _initModuleStore(ControlFactory factory, ControlModule module) {
    if (module.entries.isNotEmpty) {
      module.entries.forEach((key, value) {
        factory.set(key: key, value: value);
      });
    }

    if (module.factories.isNotEmpty) {
      module.factories.forEach((key, value) {
        factory.add(key: key, init: value);
      });
    }
  }

  List<ControlModule> getInactiveSubmodules(ControlFactory factory,
      {Map? args}) {
    final modules = <ControlModule>[];

    if (subModules.isNotEmpty) {
      if (factory.isInitialized) {
        subModules.forEach((key, value) {
          if (!factory.containsKey(key)) {
            modules.add(value(args));
          }
        });
      } else {
        subModules.forEach((key, value) {
          modules.add(value(args));
        });
      }
    }

    return modules;
  }

  Future initWithSubModules(ControlFactory factory, {Map? args}) async {
    final modules = [
      this,
      ...getInactiveSubmodules(factory, args: args),
    ];

    modules.sort();

    for (ControlModule module in modules) {
      if (module.preInit) {
        await module.init();
      }
    }

    await FutureBlock.wait([
      for (ControlModule module in modules)
        if (!module.preInit) module.init(),
    ]);
  }

  /// The asynchronous initialization logic for the module.
  ///
  /// This method is called by `Control.initControl` during the application startup process.
  /// It is the ideal place to perform any setup for the services provided by this module,
  /// such as connecting to a database, loading configuration, or initializing the `module` instance.
  Future init();

  @override
  int compareTo(ControlModule other) {
    if (priority > other.priority) {
      return -1;
    } else if (priority < other.priority) {
      return 1;
    }

    return 0;
  }
}

/// A basic, abstract implementation of [ControlModule] that provides itself as the module.
///
/// This is a convenience class for creating simple modules where the module class itself
/// holds the logic and doesn't need to provide a different object type.
///
/// It provides no default `entries` or `factories`.
class ControlProvider extends ControlModule<void> {
  /// The key is the runtime type of the `ControlProvider` instance itself.
  @override
  Type get key => runtimeType;

  /// The module instance is this `ControlProvider` instance.
  @override
  ControlProvider get module => this;

  /// By default, a `ControlProvider` does not register any entries.
  @override
  Map get entries => {};

  /// The default initialization logic is empty.
  @override
  Future init() async {}
}
