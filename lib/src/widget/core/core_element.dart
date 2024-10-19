part of flutter_control;

/// [CoreContext] of Control state management.
typedef CoreContext
    = CoreElement; //We need to build an interface, since direct use of [CoreElement] exposes a lot.

/// [CoreContext] of Control state management.
class CoreElement extends StatefulElement {
  /// Arguments of this element.
  final args = ControlArgs({});

  bool _initialized = false;

  /// Checks if element is already in use.
  bool get isInitialized => _initialized;

  /// Actual objects to dispose.
  /// We can have duplicate references here and in [args].
  List? _objects;

  @override
  CoreWidget get widget => super.widget as CoreWidget;

  @override
  CoreState get state => super.state as CoreState;

  /// Base [Element] of Control state management.
  /// It's connected to [ControlFactory] and handles object initialization, 'hooks' like arguments and their lifecycle.
  ///
  /// [CoreWidget]
  ///
  /// Check [InitProvider] and [LazyProvider] to work with dependencies.
  /// Check [CoreState] as counterpart for this element.
  CoreElement(CoreWidget widget) : super(widget) {
    args.set(widget.initArgs);
  }

  /// Called whenever dependency of State is changed.
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

  /// Called just once when State is ready.
  @protected
  @mustCallSuper
  void initRuntime() {
    widget.init(this);
  }

  /// Called just once when State is ready and Runtime is initialized.
  @protected
  @mustCallSuper
  void initState() {
    state.onInit();
    widget.onInit(args.data, this);
  }

  /// Calls [use].
  /// NOT Nullsafety - use [get] instead.
  T call<T>({dynamic key, T Function()? value, bool stateNotifier = false}) =>
      use<T>(key: key, value: value, stateNotifier: stateNotifier);

  /// Retrieve object based on [key] or [Type].
  /// When object is not found in [args], then is initialized with [value] and stored to [args].
  /// When object implements [Disposable], then is [register] for later dispose.
  ///
  /// Use custom [key] to register more Objects with same type [T].
  ///
  /// Set [stateNotifier] to [registerStateNotifier].
  /// Set [dispose] for custom resource release.
  /// NOT Nullsafety - use [get] instead.
  T use<T>(
      {dynamic key,
      required T Function()? value,
      bool stateNotifier = false,
      void Function(T object)? dispose}) {
    if (args.containsKey(key ?? T)) {
      return args.get<T>(key: key)!;
    }

    final item = args.getWithFactory<T>(key: key, defaultValue: value) ??
        Control.get<T>(key: key);

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

  /// Retrieve custom [ChangeNotifier] as [ElementValue] based on [key] or [ElementValue<Type>].
  /// When object is not found in [args], then new Value is initialized and stored to [args].
  /// Object will auto dispose with lifecycle of Element.
  ///
  /// Use custom [key] to register more [ElementValue]s with same type [T].
  ///
  /// Set [stateNotifier] to [registerStateNotifier].
  ElementValue<T> value<T>(
          {dynamic key, T? value, bool stateNotifier = false}) =>
      use<ElementValue<T>>(
        key: key,
        value: () => ElementValue<T>(value),
        stateNotifier: stateNotifier,
      );

  /// Registers object as required dependency of this Element/Widget. Object is stored to [args].
  /// When object is found in [args], just retrieve it's reference.
  ///
  /// If object is given from [ControlFactory], then Element will request dispose given object.
  /// If object is given from [scope], then Element will NOT dispose given object.
  ///
  /// Set [scope] to retrieve object from WidgetTree - Check [ControlScope].
  /// Set [stateNotifier] to also register this object as [registerStateNotifier].
  /// Check [LazyProvider] as best place to register these dependencies, alternatively use within [CoreWidget.onInit] to register dependency.
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

  /// Retrieve object from [args] based on [key] or [Type].
  /// If object is not found, then [defaultValue] is returned.
  /// Default Value is NOT stored to [args].
  T? get<T>({dynamic key, T? Function()? defaultValue}) =>
      args.get<T>(
        key: key,
      ) ??
      defaultValue?.call();

  /// Stores given [value] to [args] under given [key] or [Type].
  void set<T>({dynamic key, required T? value}) => args.add<T>(
        key: key,
        value: value,
      );

  /// Request rebuild.
  void notifyState() => state.notifyState();

  /// Registers given [object] to dispose with this Element.
  void register(dynamic object, [int priority = 0]) {
    if (object == null) {
      return;
    }

    if (_objects == null) {
      _objects = [];
    }

    if (!_objects!.contains(object)) {
      if (object is LazyHook) {
        object.hookValue = object.init(this);
      }

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

  /// Unregisters object from dispose
  void unregister(Disposable? object) {
    _objects?.remove(object);

    if (object is ReferenceCounter) {
      object.removeReference(this);
    }
  }

  /// Register this objects as state notifier
  ///
  /// Check [ControlObservable.of] for supported types.
  void registerStateNotifier(Object object) => register(
      ControlObservable.of(object).subscribe((value) => notifyState()));

  /// Dispose all registered resources.
  /// This is Callback from [CoreState].
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

/// Simple [ValueNotifier] just for [CoreElement].
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

extension ControlContextExt on BuildContext {
  RootContext get root => RootContext.of(this)!;

  ControlScope get scope => ControlScope.of(this);
}

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

mixin LazyProvider on CoreWidget {
  @override
  void init(CoreContext context) {
    mountDependencies(context);

    super.init(context);
  }

  @protected
  void mountDependencies(CoreContext context);
}

/// Provides [context] to [ControlModel].
/// USE THIS ONLY TO ENHANCE UI LOGIC.
mixin ContextComponent on ControlModel {
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
