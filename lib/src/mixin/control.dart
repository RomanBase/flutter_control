part of flutter_control;

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

/// Mixin for [ControlModel] to pass [TickerProvider] from [CoreWidget] - [ControlWidget] or [ControllableWidget].
/// Enables to construct [AnimationController] and control animations.
///
/// Typically used as private [ControlModel] next to Widget class. This solution helps to separate animation/UI logic, actual business logic and pure UI.
///
/// Also Widget must use [TickerControl] or [SingleTickerControl] to enable vsync provider or pass [TickerProvider] from other place by calling [provideTicker].
mixin TickerComponent on ControlModel {
  /// Active provider. In fact provider can be used from different [ControlModel].
  TickerProvider? _ticker;

  /// Returns active [TickerProvider] provided by Widget or passed by other Control.
  @protected
  TickerProvider? get ticker => _ticker;

  /// Checks if [TickerProvider] is set.
  bool get isTickerAvailable => _ticker != null;

  @override
  void register(dynamic object) {
    super.register(object);

    if (object is TickerProvider) {
      provideTicker(object);
    }
  }

  /// Sets vsync. Called by framework during [State] initialization when used with [CoreWidget] and [TickerControl].
  void provideTicker(TickerProvider ticker) {
    _ticker = ticker;

    onTickerInitialized(ticker);
  }

  /// Callback after [provideTicker] is executed.
  /// Serves to created [AnimationController] and to set initial animation state.
  void onTickerInitialized(TickerProvider ticker);

  @override
  void dispose() {
    super.dispose();

    _ticker = null;
  }
}

/// Mixin for [ControlModel] to pass [RouteNavigator] from [CoreWidget] - [ControlWidget] or [ControllableWidget].
/// Creates bridge to UI where [Navigator] is implemented and enables navigation from Logic class.
///
/// Check [ControlRoute] and [RouteStore] to work with routes.
///
/// Also Widget must use [RouteControl] to enable navigator and [RouteHandler].
mixin RouteNavigatorProvider on ControlModel {
  /// Implementation of [RouteNavigator].
  RouteNavigator? _navigator;

  /// Checks if [RouteNavigator] is set.
  bool get isNavigatorAvailable => _navigator != null;

  RouteNavigator? get navigator => _navigator;

  @override
  @mustCallSuper
  void register(dynamic object) {
    super.register(object);

    if (object is RouteNavigator) {
      _navigator = object;
    }
  }

  @override
  void dispose() {
    super.dispose();

    _navigator = null;
  }
}
