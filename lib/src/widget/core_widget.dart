part of flutter_control;

/// Base abstract Widget that controls [State], stores [args] and keeps Widget/State in harmony though lifecycle of Widget.
/// [CoreWidget] extends [StatefulWidget] and completely solves [State] specific flow. This solution helps to use it like [StatelessWidget], but with benefits of [StatefulWidget].
///
/// This Widget comes with [TickerControl] and [SingleTickerControl] mixin to create [Ticker] and provide access to [vsync]. Then use [ControlModel] with [TickerComponent] to get access to [TickerProvider].
///
/// [ControlWidget] - Can subscribe to multiple [ControlModel]s and is typically used for Pages and complex Widgets.
abstract class CoreWidget extends StatefulWidget {
  final Map initArgs;

  /// Base Control Widget that handles [State] flow.
  /// [args] - Arguments passed to this Widget and also to [ControlModel]s.
  ///
  /// Check [ControlWidget] and [ControllableWidget].
  const CoreWidget({
    super.key,
    this.initArgs = const {},
  });

  @override
  CoreContext createElement() => CoreContext(this, initArgs);

  @override
  CoreState createState();

  @protected
  @mustCallSuper
  void onInit(Map args, CoreContext context) {}

  /// Called whenever Widget needs update.
  /// Check [State.didUpdateWidget] for more info.
  void onUpdate(CoreWidget oldWidget) {}

  /// Called whenever dependency of Widget is changed.
  /// Check [State.didChangeDependencies] for more info.
  @protected
  void onDependencyChanged(CoreContext context) {}

  void onDispose() {}
}

class CoreContext extends StatefulElement {
  final args = ControlArgs({});

  @override
  CoreState get state => super.state as CoreState;

  CoreContext(super.widget, Map initArgs) {
    args.set(initArgs);
  }

  void initRuntime() {
    args.set(ModalRoute.of(this)?.settings.arguments);
    state.initRuntime();

    (widget as CoreWidget).onInit(args.data, this);
  }

  T? call<T>({dynamic key, T Function()? value, bool stateNotifier = false}) {
    if (args.containsKey(key ?? T)) {
      return args.get<T>(key: key);
    }

    return this.bound<T>(key: key, value: value, stateNotifier: stateNotifier);
  }

  void register(Disposable? object) {
    state.register(object);
  }

  void unregister(Disposable? object) {
    state.unregister(object);
  }

  void registerStateNotifier(dynamic object) {
    if (object is ObservableValue) {
      register(object.subscribe((value) => notifyState()));
    } else if (object is ObservableChannel) {
      register(object.subscribe(() => notifyState()));
    } else if (object is Stream || object is Future || object is Listenable) {
      register(ControlObservable.of(object).subscribe((value) => notifyState()));
    }
  }

  T? bound<T>({dynamic key, required T Function()? value, bool stateNotifier = false}) {
    final item = args.getWithFactory<T>(key: key, defaultValue: value);

    if (stateNotifier) {
      registerStateNotifier(item);
    }

    if (item is Disposable) {
      register(item);
    }

    return item;
  }

  _ArgValue<T> value<T>({dynamic key, T? value, bool stateNotifier = false}) => bound<_ArgValue<T>>(
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
}

/// [State] of [CoreWidget].
abstract class CoreState<T extends CoreWidget> extends State<T> {
  CoreContext get element => context as CoreContext;

  ControlArgs get args => element.args;

  /// Checks is State is initialized and [CoreWidget.onInit] is called just once.
  bool _stateInitialized = false;

  /// Checks if State is initialized and dependencies are set.
  bool get isInitialized => _stateInitialized;

  /// Checks if [Element] is 'dirty' and needs rebuild.
  bool get isDirty => (context as Element).dirty;

  /// Objects to dispose with State.
  List<Disposable?>? _objects;

  /// Registers object to dispose with this State.
  void register(Disposable? object) {
    if (_objects == null) {
      _objects = <Disposable?>[];
    }

    if (!_objects!.contains(object)) {
      if (object is ReferenceCounter) {
        object.addReference(this);
      }

      _objects!.add(object);
    }
  }

  /// Unregisters object to dispose from this State.
  void unregister(Disposable? object) {
    _objects?.remove(object);

    if (object is ReferenceCounter) {
      object.removeReference(this);
    }
  }

  @mustCallSuper
  void initRuntime() {}

  void notifyState() {
    if (isDirty) {
      // TODO: no need to set state.. set state next frame ?
    } else {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_stateInitialized) {
      _stateInitialized = true;
      element.initRuntime();
    }

    widget.onDependencyChanged(element);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.onUpdate(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();

    _stateInitialized = false;

    _objects?.forEach((element) {
      if (element is DisposeHandler) {
        element.requestDispose(this);
      } else {
        element!.dispose();
      }
    });

    _objects = null;

    widget.onDispose();
  }
}

abstract class ValueState<T extends StatefulWidget, U> extends State<T> {
  /// Checks if [Element] is 'mounted' or 'dirty' and marked for rebuild.
  bool get isDirty => !mounted || ((context as Element).dirty);

  /// Current value of state.
  U? value;

  void notifyValue(U? value) {
    if (isDirty) {
      this.value = value;
    } else {
      setState(() {
        this.value = value;
      });
    }
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

extension CoreContextExt on BuildContext {
  RootContext get root => RootContext.of(this)!;
}

mixin ContextComponent on ControlModel {
  CoreContext? context;

  @override
  void register(object) {
    super.register(object);

    if (object is CoreState) {
      context = object.element;
    }

    if (object is CoreContext) {
      context = object;
    }
  }
}
