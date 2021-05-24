import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_control/core.dart';

/// Holds arguments from Widget and State.
/// Helps to transfer arguments between Widget Tree rebuilds and resurrection of State.
class ControlArgHolder implements Disposable {
  /// Manually updated validity. Mostly corresponds to [State] availability.
  bool _valid = true;

  /// Holds args when [State] disposes and [Widget] goes off screen.
  ControlArgs? _cache;

  /// Current [State] of [Widget].
  CoreState? _state;

  /// Returns current [State] of [Widget].
  CoreState? get state => _state;

  /// Checks if [Widget] with current [State] is valid.
  bool get isValid => _valid;

  /// Checks if arguments cache is used and [State] is not currently available.
  bool get isCacheActive => _cache != null;

  /// Checks if [State] is available.
  bool get initialized => _state != null;

  /// Current args of [Widget] and [State].
  Map get args => argStore.data;

  /// [ControlArgs] that holds current args of [Widget] and [State].
  ControlArgs get argStore =>
      _state?.args ?? _cache ?? (_cache = ControlArgs());

  /// Initializes holder with given [state].
  /// [args] are smoothly transferred between State and Cache based on current Widget lifecycle.
  void init(CoreState? state) {
    _state = state;
    _valid = true;

    if (_cache != null) {
      argStore.set(_cache);
      _cache = null;
    }
  }

  /// Adds [args] to internal args - [ControlArgs].
  void set(dynamic args) => argStore.set(args);

  /// Returns object based on given [Type] and [key] from internal args - [ControlArgs].
  T? get<T>({dynamic key, T? defaultValue}) =>
      Parse.getArg<T>(args, key: key, defaultValue: defaultValue);

  /// Returns all [ControlModel]s from internal args - [ControlArgs].
  /// If none found, empty List is returned.
  List<ControlModel?> findControls() => argStore.getAll<ControlModel>();

  /// Copy corresponding State and args from [oldHolder].
  void copy(ControlArgHolder oldHolder) {
    if (oldHolder.initialized) {
      init(oldHolder.state);
    }

    argStore.set(oldHolder.argStore);
  }

  @override
  void dispose() {
    _cache = argStore;
    _valid = false;
    _state = null;
  }
}

/// Base abstract Widget that controls [State], stores [args] and keeps Widget/State in harmony though lifecycle of Widget.
/// [CoreWidget] extends [StatefulWidget] and completely solves [State] specific flow. This solution helps to use it like [StatelessWidget], but with benefits of [StatefulWidget].
///
/// This Widget comes with [TickerControl] and [SingleTickerControl] mixin to create [Ticker] and provide access to [vsync]. Then use [ControlModel] with [TickerComponent] to get access to [TickerProvider].
///
/// [ControlWidget] - Can subscribe to multiple [ControlModel]s and is typically used for Pages and complex Widgets.
/// [StateboundWidget] - Subscribes to just one [StateControl] - a mixin class typically used with [ControlModel] - [BaseControl] or [BaseModel]. Typically used for small Widgets.
abstract class CoreWidget extends StatefulWidget
    implements Initializable, Disposable {
  final holder = ControlArgHolder();

  /// Returns 'true' if [State] is hooked and [WidgetControlHolder] is initialized.
  bool get isInitialized => holder.initialized;

  /// Returns 'true' if [Widget] is active and [WidgetControlHolder] is not disposed.
  /// Widget is valid even when is not initialized yet.
  bool get isValid => holder.isValid;

  /// Returns [BuildContext] of current [State] if is available.
  BuildContext? get context => holder.state?.context;

  /// Base Control Widget that handles [State] flow.
  /// [args] - Arguments passed to this Widget and also to [ControlModel]s.
  ///
  /// Check [ControlWidget] and [StateboundWidget].
  CoreWidget({Key? key, dynamic args}) : super(key: key) {
    holder.set(args);
  }

  @override
  @protected
  @mustCallSuper
  void init(Map args) => addArg(args);

  @protected
  void onInit(Map args) {}

  /// Updates holder with arguments and checks if is [State] valid.
  /// Returns 'true' if [State] of this Widget is OK.
  bool _updateHolder(CoreWidget oldWidget) {
    holder.copy(oldWidget.holder);

    return !holder.initialized;
  }

  /// Called whenever Widget needs update.
  /// Check [State.didUpdateWidget] for more info.
  void onUpdate(CoreWidget oldWidget) {}

  /// Executed when [State] is changed and new [state] is available.
  /// Widget will try to resurrect State and injects args from 'cache' in [holder].
  @protected
  @mustCallSuper
  void onStateUpdate(CoreWidget oldWidget, CoreState state) {
    _notifyHolder(state);
  }

  /// Initializes and sets given [state].
  @protected
  void _notifyHolder(CoreState state) {
    assert(() {
      if (holder.initialized && holder.state != state) {
        printDebug('state re-init of: ${this.runtimeType.toString()}');
        printDebug('old state: ${holder.state}');
        printDebug('new state: $state');
      }
      return true;
    }());

    if (holder.state == state) {
      return;
    }

    holder.init(state);
  }

  /// Called whenever dependency of Widget is changed.
  /// Check [State.didChangeDependencies] for more info.
  @protected
  void onDependencyChanged() {
    if (this is ThemeProvider) {
      (this as ThemeProvider).invalidateTheme(context);
    }
  }

  /// Returns [BuildContext] of this [Widget] or 'root' context from [ControlScope].
  BuildContext? getContext({bool root: false}) =>
      root ? Control.scope.context ?? context : context;

  /// Returns raw internal arg store.
  /// Typically not used directly.
  /// Check:
  ///  - [addArg]
  ///  - [setArg]
  ///  - [getArg]
  ///  - [removeArg]
  ///  to modify arguments..
  ControlArgs getArgStore() => holder.argStore;

  /// Adds given [args] to this Widget's internal arg store.
  /// [args] can be whatever - [Map], [List], [Object], or any primitive.
  ///
  /// Check [setArg] for more 'set' options.
  /// Internally uses [ControlArgs]. Check [ControlArgs.set].
  /// Use [getArgStore] to get raw access to [ControlArgs].
  void addArg(dynamic args) => holder.set(args);

  /// Adds given [args] to this Widget's internal arg store.
  /// [args] can be whatever - [Map], [List], [Object], or any primitive.
  ///
  /// Internally uses [ControlArgs]. Check [ControlArgs.set].
  /// Use [getArgStore] to get raw access to [ControlArgs].
  void setArg<T>({dynamic key, required dynamic value}) =>
      holder.argStore.add<T>(key: key, value: value);

  /// Returns value by given [key] and [Type] from this Widget's internal arg store.
  ///
  /// Internally uses [ControlArgs]. Check [ControlArgs.get].
  /// Use [getArgStore] to get raw access to [ControlArgs].
  T? getArg<T>({dynamic key, T? defaultValue}) =>
      holder.get<T>(key: key, defaultValue: defaultValue);

  /// Removes given [arg] from this Widget's internal arg store.
  ///
  /// Internally uses [ControlArgs]. Check [ControlArgs.remove].
  /// Use [getArgStore] to get raw access to [ControlArgs].
  void removeArg<T>({dynamic key}) => holder.argStore.remove<T>(key: key);

  /// Registers object to lifecycle of [State].
  ///
  /// Widget with State must be initialized before executing this function - check [isInitialized].
  /// It's safe to register objects in/after [onInit] function.
  @protected
  void register(Disposable? object) {
    assert(isInitialized);

    holder.state!.register(object);
  }

  @protected
  void registerStateNotifier(dynamic object) {
    if (object is ActionControlObservable) {
      register(object.subscribe((value) => notifyState()));
    } else if (object is FieldControlStream) {
      register(object.subscribe((value) => notifyState()));
    } else if (object is Listenable) {
      final callback = () => notifyState();
      object.addListener(callback);
      register(DisposableClient(parent: object)
        ..onDispose = () => object.removeListener(callback));
    } else if (object is Stream) {
      register(FieldControl.of(object).subscribe((value) => notifyState()));
    } else if (object is Future) {
      register((FieldControl()..onFuture(object))
          .subscribe((value) => notifyState()));
    }
  }

  @protected
  void notifyState() => holder.state!.notifyState();

  @override
  void dispose() {}
}

/// [State] of [CoreWidget].
abstract class CoreState<T extends CoreWidget> extends State<T> {
  /// Args used via [ControlArgHolder].
  ControlArgs? _args;

  /// Args used via [ControlArgHolder].
  ControlArgs get args => _args ?? (_args = ControlArgs());

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

    if (object is ReferenceCounter) {
      object.addReference(this);
    }

    _objects!.add(object);
  }

  /// Unregisters object to dispose from this State.
  void unregister(Disposable object) {
    _objects?.remove(object);

    if (object is ReferenceCounter) {
      object.removeReference(this);
    }
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    widget._notifyHolder(this);
  }

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
      widget.onInit(_args!.data);
    }

    widget.onDependencyChanged();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    final updateState = widget._updateHolder(oldWidget);

    widget.onUpdate(oldWidget);

    if (updateState) {
      widget.onStateUpdate(oldWidget, this);
    }
  }

  @override
  void dispose() {
    super.dispose();

    _stateInitialized = false;
    widget.holder.dispose();

    _objects?.forEach((element) {
      if (element is DisposeHandler) {
        element.requestDispose(this);
      } else {
        element!.dispose();
      }
    });

    _objects = null;

    widget.dispose();
  }
}

abstract class ValueState<T extends StatefulWidget, U> extends State<T> {
  /// Checks if [Element] is 'mounted' or 'dirty' and marked for rebuild.
  bool get isDirty => !mounted || ((context as Element).dirty);

  /// Current value of state.
  U? value;

  void notifyValue(U value) {
    if (isDirty) {
      this.value = value;
    } else {
      setState(() {
        this.value = value;
      });
    }
  }
}

/// Mostly copy of [SingleTickerProviderStateMixin].
class _SingleTickerProvider implements Disposable, TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(onTick) {
    assert(() {
      if (_ticker == null) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            '$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.'),
        ErrorDescription(
            'A SingleTickerProviderStateMixin can only be used as a TickerProvider once.'),
        ErrorHint(
            'If a State is used for multiple AnimationController objects, or if it is passed to other '
            'objects and those objects might use it more than one time in total, then instead of '
            'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.')
      ]);
    }());
    _ticker =
        Ticker(onTick, debugLabel: kDebugMode ? 'created by $this' : null);
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.of(context) would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    return _ticker!;
  }

  void _muteTicker(bool muted) => _ticker?.muted = muted;

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription(
            '$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
            'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
            'be disposed before calling super.dispose().'),
        ErrorHint('Tickers used by AnimationControllers '
            'should be disposed by calling dispose() on the AnimationController itself. '
            'Otherwise, the ticker will leak.'),
        _ticker!.describeForError('The offending ticker was')
      ]);
    }());

    _ticker?.dispose();
    _ticker = null;
  }
}

/// Check [SingleTickerProviderStateMixin]
mixin SingleTickerControl on CoreWidget implements TickerProvider {
  final _ticker = _SingleTickerProvider();

  TickerProvider get ticker => this;

  @override
  Ticker createTicker(onTick) => _ticker.createTicker(onTick);

  @override
  void onInit(Map args) {
    _ticker._muteTicker(!TickerMode.of(context!));

    super.onInit(args);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// Mostly copy of [TickerProviderStateMixin].
class _TickerProvider implements Disposable, TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_WidgetTicker>{};

    final ticker = _WidgetTicker(onTick, this, debugLabel: 'created by $this');
    _tickers!.add(ticker);

    return ticker;
  }

  void _removeTicker(_WidgetTicker ticker) {
    if (_tickers == null) {
      return;
    }

    _tickers!.remove(ticker);
  }

  void _muteTicker(bool muted) =>
      _tickers?.forEach((item) => item.muted = muted);

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (Ticker ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription(
                  '$runtimeType created a Ticker via its TickerProviderStateMixin, but at the time '
                  'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                  'be disposed before calling super.dispose().'),
              ErrorHint('Tickers used by AnimationControllers '
                  'should be disposed by calling dispose() on the AnimationController itself. '
                  'Otherwise, the ticker will leak.'),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());

    _tickers?.clear();
    _tickers = null;
  }
}

/// Check [TickerProviderStateMixin]
mixin TickerControl on CoreWidget implements TickerProvider {
  final _ticker = _TickerProvider();

  TickerProvider get ticker => this;

  @override
  Ticker createTicker(TickerCallback onTick) => _ticker.createTicker(onTick);

  @override
  void onInit(Map args) {
    _ticker._muteTicker(!TickerMode.of(context!));

    super.onInit(args);
  }

  @override
  void dispose() {
    super.dispose();

    _ticker.dispose();
  }
}

/// Extended version of [TickerControl] with inside animations.
mixin TickerAnimControl<T> on CoreWidget implements TickerProvider {
  final _anim = _AnimControl<T>();

  final _ticker = _TickerProvider();

  TickerProvider get ticker => this;

  Map<T, AnimationController> get anim => _anim.controllers;

  Map<T, Duration> get animations;

  @override
  Ticker createTicker(TickerCallback onTick) => _ticker.createTicker(onTick);

  @override
  void onInit(Map args) {
    _ticker._muteTicker(!TickerMode.of(context!));
    _anim.initControllers(this, animations);

    super.onInit(args);
  }

  @override
  void dispose() {
    super.dispose();

    _anim.dispose();
    _ticker.dispose();
  }
}

class _WidgetTicker extends Ticker {
  _TickerProvider? _creator;

  bool get isMounted => _creator != null;

  _WidgetTicker(TickerCallback onTick, this._creator, {String? debugLabel})
      : super(onTick, debugLabel: debugLabel);

  @override
  void dispose() {
    _creator?._removeTicker(this);
    _creator = null;

    super.dispose();
  }
}

class _AnimControl<T> extends ControlModel {
  final controllers = Map<T, AnimationController>();

  operator [](dynamic key) => controllers[key];

  void initControllers(TickerProvider ticker, Map<T, Duration> durations) {
    durations.forEach((key, value) {
      controllers[key] = AnimationController(vsync: ticker, duration: value);
    });
  }

  @override
  void dispose() {
    super.dispose();

    controllers.forEach((key, value) => value.dispose());
    controllers.clear();
  }
}

mixin ControlsComponent on CoreWidget {
  Initializer get initComponents;

  Map get component => holder.args;

  @override
  void onInit(Map args) {
    super.onInit(args);

    dynamic components = initComponents.call(args);

    if (!(components is Map)) {
      components =
          Parse.toKeyMap(components, (key, value) => value.runtimeType);
    }

    holder.argStore.set(components);

    components.forEach((key, control) {
      if (control is Disposable) {
        register(control);
      }

      if (control is Initializable) {
        control.init(holder.args);
      }

      if (control is TickerComponent && this is TickerProvider) {
        control.provideTicker(this as TickerProvider);
      }
    });
  }
}

mixin OnLayout on CoreWidget {
  @override
  void onInit(Map args) {
    super.onInit(args);

    WidgetsBinding.instance!.addPostFrameCallback((_) => onLayout());
  }

  void onLayout();
}

/// Debug printer of [CoreWidget] lifecycle.
mixin CoreWidgetDebugPrinter on CoreWidget {
  @override
  void init(Map args) {
    printDebug('CORE $this: init --- $args');
    super.init(args);
  }

  @override
  void onInit(Map args) {
    printDebug('CORE $this: on init --- $args');
    super.onInit(args);
  }

  @override
  void onUpdate(CoreWidget oldWidget) {
    printDebug('CORE $this: on update --- $oldWidget');
    super.onUpdate(oldWidget);
  }

  @override
  void onStateUpdate(CoreWidget oldWidget, CoreState<CoreWidget> state) {
    printDebug('CORE $this: on state update --- $oldWidget | $state');
    super.onStateUpdate(oldWidget, state);
  }

  @override
  void onDependencyChanged() {
    printDebug('CORE $this: dependency changed');
    super.onDependencyChanged();
  }

  @override
  void dispose() {
    printDebug('CORE $this: dispose');
    super.dispose();
  }
}
