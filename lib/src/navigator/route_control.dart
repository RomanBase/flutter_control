part of flutter_control;

typedef RouteBuilderFactory = Route<dynamic> Function(
    WidgetBuilder builder, RouteSettings settings);
typedef RouteArgFactory = dynamic Function(RouteArgs args);
typedef RouteTransitionFactory = Widget Function(
    BuildContext context, ControlRouteTransitionSetup setup, Widget child);

/// Ties up [RouteNavigator] and [ControlRoute].
///
/// Initializes [Widget], builds [Route] with given properties and pushes this route to [Navigator].
/// Do not open multiple routes from one handler !
class RouteHandler {
  /// Implementation of navigator.
  final RouteNavigator navigator;

  /// Implementation of provider.
  final ControlRoute routeProvider;

  /// Future of navigation result.
  Future<dynamic>? _result;

  /// Future of navigation result.
  /// This future is finished when Route is closed.
  Future<dynamic>? get result => _result;

  /// Current route.
  Route? _route;

  /// Actual [Route] build.
  Route? get route => _route;

  /// Checks if this handler did his job.
  /// Do not open multiple routes from one handler !
  bool get isHandled => _result != null;

  /// Route name. This identifier is typically stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  String? get identifier => routeProvider.identifier;

  /// Builds [Widget] and pushes [Route] to [Navigator].
  ///
  /// [navigator] - Implementation of [RouteNavigator] - typically [ControlWidget] with [RouteControl] mixin.
  /// [routeProvider] - Route settings and builder.
  ///
  /// Do not open multiple routes from one handler !
  RouteHandler(this.navigator, this.routeProvider);

  /// Creates copy of [RouteHandler] with given builder.
  ///
  /// @{macro route-route}
  RouteHandler viaRoute(RouteBuilderFactory builder) =>
      RouteHandler(navigator, routeProvider.viaRoute(builder));

  /// Creates copy of [RouteHandler] with given transition.
  ///
  /// @{macro route-transition}
  RouteHandler viaTransition(RouteTransitionFactory transition) =>
      RouteHandler(navigator, routeProvider.viaTransition(transition));

  /// Creates copy of [RouteHandler] with given path name.
  ///
  /// @{macro route-path}
  RouteHandler path(
          {InitFactory<dynamic>? name, InitFactory<dynamic>? query}) =>
      RouteHandler(navigator, routeProvider.path(path: name, query: query));

  /// Creates copy of [RouteHandler] with given identifier.
  ///
  /// @{macro route-named}
  RouteHandler named(String identifier) =>
      RouteHandler(navigator, routeProvider.named(identifier));

  /// @{macro route-open}
  Future<dynamic>? openRoute(
      {bool root = false, bool replacement = false, dynamic args}) {
    printDebug("open route: ${routeProvider.identifier} from $navigator");

    _result = navigator.openRoute(
      _route = routeProvider.init(args: args),
      root: root,
      replacement: replacement,
    );

    return _result;
  }

  /// {@macro route-root}
  Future<dynamic>? openRoot({dynamic args}) {
    printDebug("open root: ${routeProvider.identifier} from $navigator");

    _result = navigator.openRoot(_route = routeProvider.init(args: args));

    return _result;
  }

  /// @{macro route-dialog}
  Future<dynamic> openDialog({bool root = true, dynamic type, dynamic args}) {
    printDebug("open dialog: ${routeProvider.identifier} from $navigator");

    _route = null;
    return _result = navigator.openDialog(
      routeProvider.buildInitializer().wrap(args: args),
      root: root,
      type: type,
    );
  }
}

/// [Route] builder with given settings.
/// Using [Type] as route identifier is recommended.
class ControlRoute {
  static RouteStore get _store => Control.get<RouteStore>()!;

  /// Builds [Route] via [builder] with given [identifier] and [settings].
  /// [Type] or [identifier] is required - check [RouteStore.routeIdentifier] for more info about Store keys.
  /// [mask] - specific url mask, that can be used for dynamic routing - check [RouteStore.routePathMask] for more info. E.g. /project/{pid}/user{uid}
  /// [settings] - Additional [Route] settings.
  ///
  /// Typically used within [Control.initControl] or [ControlRoot].
  /// ```
  ///   routes: [
  ///     ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
  ///     ControlRoute.build(identifier: 'settings', builder: (_) => SettingsPage()),
  ///   ]
  /// ```
  /// Using [Type] as route identifier is recommended.
  static ControlRoute build<T>({
    dynamic identifier,
    required InitWidgetBuilder builder,
    Object? arguments,
    String? mask,
    RouteArgFactory? path,
    RouteArgFactory? query,
  }) {
    assert(T != dynamic || identifier != null);

    return ControlRoute._()
      ..identifier = RouteStore.routeIdentifier<T>(identifier)
      .._builder = builder
      .._arguments = arguments
      .._mask = mask
      .._pathBuilder = path
      .._queryBuilder = query;
  }

  /// Holds [Route] with given [identifier].
  /// Useful for specific or generated Routes.
  ///
  /// Check [RouteControl.build] for classic [WidgetBuilder] version.
  static ControlRoute route<T>({
    dynamic identifier,
    required Route route,
    String? mask,
    RouteArgFactory? path,
    RouteArgFactory? query,
  }) =>
      ControlRoute._()
        ..identifier = RouteStore.routeIdentifier<T>(identifier)
        .._routeBuilder = (_, __) {
          return route;
        }
        .._mask = mask
        .._pathBuilder = path
        .._queryBuilder = query;

  /// Route name. This identifier is typically stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  late String identifier;

  /// {@template route-path}
  String? _mask;

  /// Additional route settings.
  Object? _arguments;

  /// Required Widget builder.
  InitWidgetBuilder? _builder;

  /// Custom Route builder.
  RouteBuilderFactory? _routeBuilder;

  /// {@template route-path}
  RouteArgFactory? _pathBuilder;

  /// {@template route-path}
  RouteArgFactory? _queryBuilder;

  /// Default private constructor.
  /// Use static constructors - [ControlRoute.build], [ControlRoute.route] or [ControlRoute.of].
  ControlRoute._();

  WidgetInitializer buildInitializer() {
    assert(_builder != null);

    return WidgetInitializer.initOf(_builder!);
  }

  String _buildPath(RouteArgs args) => RouteStore.routePathIdentifier(
        identifier: identifier,
        path: _pathBuilder?.call(args),
        args: _queryBuilder?.call(args),
      );

  /// Builds [Route] with specified [RouteWidgetBuilder] or with default [MaterialPageRoute]/[CupertinoPageRoute].
  /// Also [identifier] and [settings] are passed to Route as [RouteSettings].
  Route _buildRoute(WidgetBuilder builder, String? path) {
    final routeSettings =
        RouteSettings(name: path ?? identifier, arguments: _arguments);

    if (_routeBuilder != null) {
      return _routeBuilder!.call(builder, routeSettings);
    }

    if (kIsWeb) {
      return MaterialPageRoute(builder: builder, settings: routeSettings);
    }

    if (Platform.isIOS) {
      return CupertinoPageRoute(builder: builder, settings: routeSettings);
    }

    return MaterialPageRoute(builder: builder, settings: routeSettings);
  }

  /// Builds [Route] with specified [RouteWidgetBuilder] or with default [MaterialPageRoute]/[CupertinoPageRoute].
  /// Also [identifier] and [settings] are passed to Route as [RouteSettings].
  /// Given [args] are passed to Widget.
  Route init({dynamic args}) {
    assert(_builder != null);

    final initializer = buildInitializer();

    final route = _buildRoute(
      initializer.wrap(args: args),
      _buildPath(RouteArgs._(this, RouteMask.of(_mask ?? identifier), args)),
    );

    initializer.data = route;

    return route;
  }

  /// {@template route-route}
  /// Setups new [routeBuilder] and returns copy of [ControlRoute] with new settings..
  /// {@endtemplate}
  ControlRoute viaRoute(RouteBuilderFactory routeBuilder) =>
      _copyWith(routeBuilder: routeBuilder);

  /// {@macro route-route}
  /// Via [MaterialPageRoute].
  ControlRoute viaMaterialRoute() => viaRoute((builder, settings) =>
      MaterialPageRoute(builder: builder, settings: settings));

  /// {@macro route-route}
  /// Via [CupertinoPageRoute].
  ControlRoute viaCupertinoRoute() => viaRoute((builder, settings) =>
      CupertinoPageRoute(builder: builder, settings: settings));

  /// {@template route-transition}
  /// Setups new [transition] with given [duration] and returns copy of [ControlRoute] with new settings..
  /// [ControlRouteTransition] is used as [PageRoute].
  /// {@endtemplate}
  ControlRoute viaTransition(RouteTransitionFactory transition,
          [Duration duration = const Duration(milliseconds: 300)]) =>
      _copyWith(
          routeBuilder: (builder, settings) => ControlRouteTransition(
                builder: builder,
                transition: transition,
                duration: duration,
                settings: settings,
              ));

  /// {@template route-path}
  /// Alters current [identifier] with given [path] and [query] args and returns copy of [ControlRoute] with new settings.
  /// ```
  /// ControlRoute.of<DetailPage>(identifier: 'detail').path(path: (_) => 'node', query: (args) => {'id': args['id']});
  /// refers to: /detail/node?id=1
  /// ```
  /// {@endtemplate}
  ControlRoute path(
          {RouteArgFactory? path, RouteArgFactory? query, String? mask}) =>
      _copyWith(
        path: path,
        query: query,
        mask: mask,
      );

  /// {@template route-name}
  /// Changes current [identifier] and returns copy of [ControlRoute] with new settings..
  /// {@endtemplate}
  ControlRoute named(String identifier) => _copyWith(
        identifier: identifier,
      );

  /// Creates copy of [RouteControl] with given settings.
  ControlRoute _copyWith({
    dynamic identifier,
    String? mask,
    Object? arguments,
    RouteBuilderFactory? routeBuilder,
    RouteArgFactory? path,
    RouteArgFactory? query,
  }) =>
      ControlRoute._()
        ..identifier = identifier ?? this.identifier
        .._mask = mask ?? this._mask
        .._arguments = arguments ?? this._arguments
        .._builder = _builder
        .._routeBuilder = routeBuilder ?? this._routeBuilder
        .._pathBuilder = path
        .._queryBuilder = query;

  /// Initializes [RouteHandler] with given [navigator] and this Route provider.
  RouteHandler navigator(RouteNavigator navigator) =>
      RouteHandler(navigator, this);

  /// Registers this Route to global [RouteStore].
  void register<T>() => _store.addRoute<T>(this);

  /// @{template route-store-get}
  /// Returns [ControlRoute] from [RouteStore] by given [Type] or [identifier].
  /// [Type] or [identifier] is required - check [RouteStore.routeIdentifier] for more info about Store keys.
  ///
  /// [RouteStore] is typically filled during [Control.initControl] or via [ControlRoot].
  /// [RouteStore] is also stored in [Control] -> [Control.get<RouteStore>()] and can be updated anytime,
  ///
  /// Using [Type] as route identifier is recommended.
  /// @{endtemplate}
  static ControlRoute? of<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return _store.getRoute<T>(identifier);
  }

  /// Returns identifier of Route stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  static String? identifierOf<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return _store.getRoute<T>(identifier)?.identifier;
  }
}

/// Custom [PageRoute] building Widget via given [RouteTransitionFactory].
class ControlRouteTransition extends PageRoute {
  /// Builder of Widget.
  final WidgetBuilder builder;

  /// Builder of Transition.
  final RouteTransitionFactory transition;

  /// Duration of transition Animation.
  final Duration duration;

  /// Simple [PageRoute] with custom [transition].
  ControlRouteTransition({
    required this.builder,
    required this.transition,
    this.duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PageRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is PageRoute;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: builder(context),
      );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      transition(
          context,
          ControlRouteTransitionSetup._(
            animation,
            secondaryAnimation,
            this,
          ),
          child);
}

class ControlRouteTransitionSetup {
  final Animation<double> incomingAnimation;
  final Animation<double> outgoingAnimation;
  final ControlRouteTransition route;

  RouteSettings? get settings => route.settings;

  bool get root => route.isFirst;

  bool get active => route.isActive;

  bool get foregroundIncoming =>
      (incomingAnimation.status == AnimationStatus.forward ||
          incomingAnimation.isCompleted) &&
      outgoingAnimation.isDismissed;

  bool get foregroundOutgoing =>
      (incomingAnimation.status == AnimationStatus.reverse ||
          incomingAnimation.isDismissed) &&
      outgoingAnimation.isDismissed;

  bool get backgroundIncoming =>
      (outgoingAnimation.status == AnimationStatus.reverse ||
          outgoingAnimation.isDismissed) &&
      incomingAnimation.isCompleted;

  bool get backgroundOutgoing =>
      (outgoingAnimation.status == AnimationStatus.forward ||
          outgoingAnimation.isCompleted) &&
      incomingAnimation.isCompleted;

  bool get foregroundActive => outgoingAnimation.isDismissed;

  bool get backgroundActive => incomingAnimation.isCompleted;

  const ControlRouteTransitionSetup._(
    this.incomingAnimation,
    this.outgoingAnimation,
    this.route,
  );

  ControlRouteTransitionSetup curved({
    Curve? incomingCurve,
    Curve? outgoingCurve,
  }) =>
      ControlRouteTransitionSetup._(
        incomingCurve == null
            ? this.incomingAnimation
            : CurvedAnimation(
                parent: this.incomingAnimation, curve: incomingCurve),
        outgoingCurve == null
            ? this.outgoingAnimation
            : CurvedAnimation(
                parent: this.outgoingAnimation, curve: outgoingCurve),
        this.route,
      );
}
