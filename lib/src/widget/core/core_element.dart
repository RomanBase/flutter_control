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

  void initRuntime() {
    args.set(ModalRoute.of(this)?.settings.arguments);
  }

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
      return args.get<T>(key: key);
    }

    final item = args.getWithFactory<T>(key: key, defaultValue: value);

    assert(item != null, 'There is nothing to take: $T | $key');

    if (stateNotifier) {
      registerStateNotifier(item);
    }

    if (dispose != null) {
      register(DisposableClient()..onDispose = () => dispose(item!), 1);
    } else if (item is Disposable) {
      register(item);
    }

    return item;
  }

  _ArgValue<T> value<T>({dynamic key, T? value, bool stateNotifier = false}) =>
      use<_ArgValue<T>>(
        key: key,
        value: () => _ArgValue<T>(value),
        stateNotifier: stateNotifier,
      )!;

  T? getControl<T>({dynamic key, bool scope = false}) => scope
      ? this.scope.get<T>(key: key, args: args.data)
      : Control.resolve<T>(
          this.args.data,
          key: key,
          args: args.data,
        );

  T? get<T>({dynamic key, T? Function()? defaultValue}) =>
      args.get<T>(
        key: key,
      ) ??
      defaultValue?.call();

  void set<T>({dynamic key, required T? value}) => args.add(
        key: key,
        value: value,
      );

  void notifyState() => state.notifyState();

  /// Registers object to dispose
  void register(dynamic object, [int priority = 0]) {
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

class _ArgValue<T> extends ChangeNotifier {
  T? _value;

  _ArgValue(T? value) : _value = value;

  T? get value => _value;

  set value(T? value) {
    if (_value != value) {
      _value = value;
      notifyListeners();
    }
  }
}
