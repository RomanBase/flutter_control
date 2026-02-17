part of flutter_control;

/// The core [BuildContext] for the Control framework.
///
/// It extends [StatefulElement] and serves as the central point for state
/// management, dependency injection, and resource lifecycle within a [CoreWidget].
///
/// It is aliased as [CoreContext] for easier use in build methods.
typedef CoreContext
    = CoreElement; //We need to build an interface, since direct use of [CoreElement] exposes a lot.

/// The core [Element] for the Control framework.
///
/// It extends [StatefulElement] and serves as the central point for state

/// It's connected to [ControlFactory] and handles object initialization,
/// "hooks" like arguments, and their lifecycle.
///
/// See also:
///  - [CoreWidget], the widget that creates this element.
///  - [CoreState], the state object associated with this element.
///  - [InitProvider] and [LazyProvider] for dependency injection patterns.
class CoreElement extends StatefulElement {
  /// A map of arguments and dependencies associated with this element.
  final args = ControlArgs({});

  bool _initialized = false;

  /// Whether the element has been initialized.
  bool get isInitialized => _initialized;

  /// A list of objects that should be disposed when this element is disposed.
  List? _objects;

  @override
  CoreWidget get widget => super.widget as CoreWidget;

  @override
  CoreState get state => super.state as CoreState;

  /// Creates a [CoreElement].
  CoreElement(CoreWidget widget) : super(widget) {
    args.set(widget.initArgs);
  }

  /// Called by the framework when the dependencies of this state change.
  @protected
  @mustCallSuper
  void onDependencyChanged() {
    if (!_initialized) {
      _initialized = true;
      initRuntime();
      initState();
    }

    _objects?.forEach((element) {
      if (element is LazyHook) {
        element.onDependencyChanged(this);
      }
    });
  }

  /// Initializes the runtime, called once when the state is ready.
  @protected
  @mustCallSuper
  void initRuntime() {
    widget.init(this);
  }

  /// Initializes the state, called once after the runtime is initialized.
  @protected
  @mustCallSuper
  void initState() {
    state.onInit();
    widget.onInit(args.data, this);
  }

  /// A shorthand for [use].
  T call<T>({dynamic key, T Function()? value, bool stateNotifier = false}) =>
      use<T>(key: key, value: value, stateNotifier: stateNotifier);

  /// Retrieves or initializes a dependency.
  ///
  /// This is the primary "hook" method in the framework.
  ///
  /// If an object of type [T] (or identified by [key]) already exists in the
  /// element's arguments, it is returned. Otherwise, the [value] function is
  /// called to create it, and the new object is stored.
  ///
  /// If the created object is [Disposable], it is automatically registered for disposal.
  ///
  /// - [key]: An optional key to distinguish between multiple instances of the same type.
  /// - [value]: A factory function to create the object if it doesn't exist.
  /// - [stateNotifier]: If `true`, the widget will rebuild when the object notifies listeners.
  /// - [dispose]: A custom disposal function for the object.
  T use<T>(
      {dynamic key,
      required T Function()? value,
      bool stateNotifier = false,
      void Function(T object)? dispose}) {
    if (args.containsKey(key ?? T)) {
      return args.get<T>(key: key)!;
    }

    final item =
        args.use<T>(key: key, defaultValue: value) ?? Control.get<T>(key: key);

    assert(item != null,
        'There is nothing to take: $T | $key. Please provide [T Function()? value] or register new factory/entry within ControlFactory');

    if (stateNotifier) {
      registerStateNotifier(item!);
    }

    if (dispose != null) {
      register(DisposableClient()..onDispose = () => dispose(item!), 1);
    } else if (item is Disposable) {
      register(item);
    }

    return item!;
  }

  /// Retrieves or initializes a simple [ValueNotifier] of type [T].
  ///
  /// This is a convenience method for managing simple mutable state within a widget.
  /// The [ElementValue] will be automatically disposed.
  ElementValue<T> value<T>(
          {dynamic key, T? value, bool stateNotifier = false}) =>
      use<ElementValue<T>>(
        key: key,
        value: () => ElementValue<T>(value),
        stateNotifier: stateNotifier,
      );

  /// Registers a dependency that is retrieved from an external source, either
  /// the global [ControlFactory] or a parent [ControlScope].
  ///
  /// - [key]: An optional key to identify the dependency.
  /// - [scope]: If `true`, searches for the dependency in the widget tree using [ControlScope].
  ///   Otherwise, retrieves it from the global [ControlFactory].
  /// - [stateNotifier]: If `true`, registers the dependency as a state notifier.
  T? registerDependency<T>(
      {dynamic key, bool scope = false, bool stateNotifier = false}) {
    if (args.containsKey(key ?? T)) {
      return args.get<T>(key: key);
    }

    T? item;
    if (scope) {
      item = this.scope.get<T>(key: key, args: args.data);
    } else {
      item = Control.get<T>(key: key);
      register(item);
    }

    if (item != null) {
      args.add<T>(key: key, value: item);

      if (stateNotifier) {
        registerStateNotifier(item);
      }
    }

    return item;
  }

  /// Retrieves an object from this element's argument map.
  ///
  /// Returns [defaultValue] if the object is not found.
  T? get<T>({dynamic key, T? Function()? defaultValue}) =>
      args.get<T>(
        key: key,
      ) ??
      defaultValue?.call();

  /// Stores a [value] in this element's argument map.
  void set<T>({dynamic key, required T? value}) => args.add<T>(
        key: key,
        value: value,
      );

  /// Schedules a rebuild for the widget.
  void notifyState() => state.notifyState();

  /// Registers an object to be disposed when this element is unmounted.
  ///
  /// If the object is a [ReferenceCounter], its reference count is incremented.
  void register(dynamic object, [int priority = 0]) {
    if (object == null) {
      return;
    }

    if (_objects == null) {
      _objects = [];
    }

    if (!_objects!.contains(object)) {
      if (object is ReferenceCounter) {
        object.addReference(this);
      }

      if (priority > 0) {
        _objects!.insert(0, object);
      } else {
        _objects!.add(object);
      }
    }
  }

  /// Unregisters an object, preventing it from being disposed with this element.
  void unregister(Disposable? object) {
    _objects?.remove(object);

    if (object is ReferenceCounter) {
      object.removeReference(this);
    }
  }

  /// Registers an object as a state notifier. The widget will rebuild whenever
  /// the object notifies of a change.
  ///
  /// See [ControlObservable.of] for supported types.
  void registerStateNotifier(Object object) => register(
      ControlObservable.of(object).subscribe((value) => notifyState()));

  /// Disposes all registered resources. Called by [CoreState.dispose].
  void onDispose() {
    _initialized = false;

    _objects?.forEach((element) {
      if (element is DisposeHandler) {
        element.requestDispose(this);
      } else if (element is Disposable) {
        element.dispose();
      } else if (element is ChangeNotifier) {
        element.dispose();
      }
    });

    _objects = null;

    args.clear();
  }
}

/// A simple [ValueNotifier] for use within a [CoreElement].
class ElementValue<T> extends ChangeNotifier {
  T? _value;

  ElementValue(T? value) : _value = value;

  T? get value => _value;

  set value(T? value) {
    if (_value != value) {
      _value = value;
      notifyListeners();
    }
  }
}

/// Extension on [BuildContext] for common Control framework operations.
extension ControlContextExt on BuildContext {
  /// The root context of the application.
  RootContext get root => RootContext.of(this)!;

  /// A [ControlScope] for dependency lookup.
  ControlScope get scope => ControlScope.of(this);

  /// Unfocuses the primary focus node.
  void unfocus() => primaryFocus?.unfocus();
}

/// A mixin for a [CoreWidget] that initializes its arguments from the current [ModalRoute].
mixin InitProvider on CoreWidget {
  @override
  void init(CoreContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null) {
      context.args.set(args);
    }

    super.init(context);
  }
}

/// A mixin for a [CoreWidget] that requires custom dependency mounting.
mixin LazyProvider on CoreWidget {
  @override
  void init(CoreContext context) {
    mountDependencies(context);

    super.init(context);
  }

  /// A dedicated method for mounting dependencies using [CoreContext.registerDependency].
  @protected
  void mountDependencies(CoreContext context);
}

/// A mixin for a [ControlModel] to gain access to the [CoreContext] of its host widget.
///
/// This should be used sparingly, primarily for UI-related logic within a model.
mixin ContextComponent on ControlModel {
  /// The [CoreContext] of the host widget.
  CoreContext? context;

  @override
  void mount(object) {
    super.mount(object);

    if (object is CoreState) {
      context = object.element;
    }

    if (object is CoreContext) {
      context = object;
    }
  }
}
