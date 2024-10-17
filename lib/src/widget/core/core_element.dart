part of flutter_control;

//So we can easily switch to interface/mixin for Stateless implementation.
typedef CoreContext = CoreElement;

class CoreElement extends StatefulElement {
  final args = ControlArgs({});

  bool _initialized = false;

  bool get isInitialized => _initialized;

  List? _objects;

  @override
  CoreWidget get widget => super.widget as CoreWidget;

  @override
  CoreState get state => super.state as CoreState;

  CoreElement(CoreWidget widget, Map initArgs) : super(widget) {
    args.set(initArgs);
  }

  /// Called whenever dependency of State is changed.
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
  void initRuntime() {
    if (widget is InitProvider) {
      args.set((widget as InitProvider).getRouteDependencies(this));
    }

    if (widget is LazyProvider) {
      (widget as LazyProvider).mountDependencies(this);
    }
  }

  /// Called just once when State is ready and Runtime is initialized.
  void initState() {
    state.onInit();
    widget.onInit(args.data, this);
  }

  T? call<T>({dynamic key, T Function()? value, bool stateNotifier = false}) =>
      use<T>(key: key, value: value, stateNotifier: stateNotifier);

  T? use<T>(
      {dynamic key,
      required T Function()? value,
      bool stateNotifier = false,
      void Function(T object)? dispose}) {
    if (args.containsKey(key ?? T)) {
      return args.get<T>(key: key)!;
    }

    final item = args.getWithFactory<T>(key: key, defaultValue: value) ??
        Control.factory.get<T>(key: key);

    assert(item != null,
        'There is nothing to take: $T | $key. Please provide [T Function()? value]');

    if (stateNotifier) {
      registerStateNotifier(item);
    }

    if (dispose != null) {
      register(DisposableClient()..onDispose = () => dispose(item!), 1);
    } else if (item is Disposable) {
      register(item);
    }

    return item!;
  }

  ElementValue<T> value<T>(
          {dynamic key, T? value, bool stateNotifier = false}) =>
      use<ElementValue<T>>(
        key: key,
        value: () => ElementValue<T>(value),
        stateNotifier: stateNotifier,
      )!;

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

  T? get<T>({dynamic key, T? Function()? defaultValue}) =>
      args.get<T>(
        key: key,
      ) ??
      defaultValue?.call();

  void set<T>({dynamic key, required T? value}) => args.add<T>(
        key: key,
        value: value,
      );

  void notifyState() => state.notifyState();

  /// Registers object to dispose
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

  void registerStateNotifier(dynamic object) {
    if (object is ObservableValue) {
      register(object.subscribe((value) => notifyState()));
    } else if (object is ObservableChannel) {
      register(object.subscribe(() => notifyState()));
    } else if (object is Stream || object is Future || object is Listenable) {
      register(
          ControlObservable.of(object).subscribe((value) => notifyState()));
    }
  }

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
  @protected
  Object getRouteDependencies(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments ?? [];
}

mixin LazyProvider on CoreWidget {
  @protected
  void mountDependencies(CoreContext context) {}
}

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
