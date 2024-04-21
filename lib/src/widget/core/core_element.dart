part of flutter_control;

class CoreContext extends StatefulElement {
  final args = ControlArgs({});

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Objects to dispose with State.
  List? _objectsToDispose;

  @override
  CoreWidget get widget => super.widget as CoreWidget;

  @override
  CoreState get state => super.state as CoreState;

  CoreContext(CoreWidget widget, Map initArgs) : super(widget) {
    args.set(initArgs);
  }

  void onDependencyChanged() {
    if (!_initialized) {
      _initialized = true;
      initRuntime();
      initState();
    }
  }

  void initRuntime() {
    args.set(ModalRoute.of(this)?.settings.arguments);
  }

  void initState() {
    state.onInit();
    widget.onInit(args.data, this);
  }

  T? call<T>({dynamic key, T Function()? value, bool stateNotifier = false}) {
    if (args.containsKey(key ?? T)) {
      return args.get<T>(key: key);
    }

    return this.use<T>(key: key, value: value, stateNotifier: stateNotifier);
  }

  T? use<T>(
      {dynamic key, required T Function()? value, bool stateNotifier = false, void Function(T object)? dispose}) {
    final item = args.getWithFactory<T>(key: key, defaultValue: value);

    assert(item != null, 'There is nothing to take: $T | $key');

    if (stateNotifier) {
      registerStateNotifier(item);
    }

    if(dispose != null){
      register(DisposableClient()..onDispose = () => dispose(item!));
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

  T? getControl<T>({dynamic key, dynamic args}) => Control.resolve<T>(
        this.args.data,
        key: key,
        args: args ?? this.args.data,
      );

  T? get<T>({dynamic key}) => this.args.get<T>(
        key: key,
      );

  void set<T>({dynamic key, required T? value}) => this.args.add(
        key: key,
        value: value,
      );

  void notifyState() => state.notifyState();

  /// Registers object to dispose
  void register(dynamic object) {
    if (_objectsToDispose == null) {
      _objectsToDispose = [];
    }

    if (!_objectsToDispose!.contains(object)) {
      if (object is ReferenceCounter) {
        object.addReference(this);
      }

      _objectsToDispose!.add(object);
    }
  }

  /// Unregisters object from dispose
  void unregister(Disposable? object) {
    _objectsToDispose?.remove(object);

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

    _objectsToDispose?.forEach((element) {
      if (element is DisposeHandler) {
        element.requestDispose(this);
      } else if (element is Disposable) {
        element.dispose();
      } else if (element is ChangeNotifier) {
        element.dispose();
      }
    });

    _objectsToDispose = null;

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
