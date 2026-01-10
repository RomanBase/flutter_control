part of flutter_control;

typedef RouteBuilderFactory<T> = Route<T> Function(
    WidgetBuilder builder, RouteSettings settings);
typedef RouteArgFactory = dynamic Function(RouteArgs args);
typedef RouteTransitionFactory = Widget Function(
    BuildContext context, ControlRouteTransitionSetup setup, Widget child);

/// Defines a route, its builder, and navigation settings.
///
/// This class is used to register routes in the [RouteStore] and provides a
/// fluent API for customizing route behavior, such as transitions and path parameters.
/// Using a [Type] as a route identifier is recommended for type-safe navigation.
class ControlRoute {
  static RouteStore get _store => Control.get<RouteStore>()!;

  /// Creates a [ControlRoute] from a [WidgetBuilder].
  ///
  /// A [Type] or [identifier] is required to uniquely identify the route.
  ///
  /// [mask] A specific URL mask for dynamic routing (e.g., `/project/{pid}/user/{uid}`).
  /// [path] A factory to build dynamic path segments.
  /// [query] A factory to build query parameters.
  ///
  /// Typically used within [Control.initControl] or [ControlRoot]:
  /// ```
  ///   routes: [
  ///     ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
  ///     ControlRoute.build(identifier: 'settings', builder: (_) => SettingsPage()),
  ///   ]
  /// ```
  static ControlRoute build<T>({
    dynamic identifier,
    required WidgetBuilder builder,
    String? mask,
    RouteArgFactory? path,
    RouteArgFactory? query,
  }) {
    assert(T != dynamic || identifier != null);

    return ControlRoute._()
      ..identifier = RouteStore.routeIdentifier<T>(identifier)
      .._builder = builder
      .._mask = mask
      .._pathBuilder = path
      .._queryBuilder = query;
  }

  /// Creates a [ControlRoute] from a pre-built [Route] object.
  /// Useful for integrating with third-party packages or custom [Route] implementations.
  ///
  /// Check [ControlRoute.build] for the standard [WidgetBuilder] approach.
  static ControlRoute route<T>({
    dynamic identifier,
    required Route route,
    String? mask,
    RouteArgFactory? path,
    RouteArgFactory? query,
  }) =>
      ControlRoute._()
        ..identifier = RouteStore.routeIdentifier<T>(identifier)
        .._mask = mask
        .._pathBuilder = path
        .._queryBuilder = query
        ..viaRoute((builder, settings) => route);

  /// The unique identifier for the route.
  /// See [RouteStore.routeIdentifier] for more info on how keys are generated.
  late String identifier;

  /// The route's path mask for dynamic routing.
  RouteMask get mask => RouteMask.of(_mask ?? identifier);

  String? _mask;

  /// The builder for the route's widget.
  WidgetBuilder? _builder;

  /// The custom builder for the [Route] itself (e.g., [MaterialPageRoute]).
  RouteBuilderFactory? _routeBuilder;

  /// The factory for building dynamic path segments.
  RouteArgFactory? _pathBuilder;

  /// The factory for building query parameters.
  RouteArgFactory? _queryBuilder;

  /// Private constructor. Use one of the static factory methods to create an instance.
  ControlRoute._();

  String pathOf([dynamic args]) => _buildPath(RouteArgs._(this, mask, args));

  String _buildPath(RouteArgs args) => RouteStore.routePathIdentifier(
        identifier: identifier,
        path: _pathBuilder?.call(args),
        args: _queryBuilder?.call(args),
      );

  /// Builds a [Route] with the specified settings.
  ///
  /// This method uses the configured [_routeBuilder] or defaults to
  /// [MaterialPageRoute] or [CupertinoPageRoute] based on the platform.
  Route<dynamic> _buildRoute<T>(
      WidgetBuilder builder, String? path, dynamic args) {
    final routeSettings = RouteSettings(
        name: path ?? identifier, arguments: ControlArgs.of(args));

    if (_routeBuilder != null) {
      return _routeBuilder!.call(builder, routeSettings);
    }

    if (kIsWeb) {
      return MaterialPageRoute<T>(builder: builder, settings: routeSettings);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPageRoute<T>(builder: builder, settings: routeSettings);
    }

    return MaterialPageRoute<T>(builder: builder, settings: routeSettings);
  }

  Widget buildView(BuildContext context) {
    assert(_builder != null);

    return _builder!.call(context);
  }

  /// Initializes the route with the given arguments and returns a [Route] instance.
  Route<dynamic> init<T>({dynamic args}) {
    assert(_builder != null);

    final route = _buildRoute<T>(
      _builder!,
      _buildPath(RouteArgs._(this, RouteMask.of(_mask ?? identifier), args)),
      args,
    );

    return route;
  }

  /// {@template route-route}
  /// Returns a copy of this route with a custom [routeBuilder].
  /// {@endtemplate}
  ControlRoute viaRoute(RouteBuilderFactory routeBuilder) =>
      _copyWith(routeBuilder: routeBuilder);

  /// {@macro route-route}
  /// Uses [MaterialPageRoute] as the route builder.
  ControlRoute viaMaterialRoute() => viaRoute((builder, settings) =>
      MaterialPageRoute(builder: builder, settings: settings));

  /// {@macro route-route}
  /// Uses [CupertinoPageRoute] as the route builder.
  ControlRoute viaCupertinoRoute() => viaRoute((builder, settings) =>
      CupertinoPageRoute(builder: builder, settings: settings));

  /// {@template route-transition}
  /// Returns a copy of this route that uses a custom [transition].
  /// The route will be a [ControlRouteTransition].
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
  /// Returns a copy of this route with altered path and query parameters.
  ///
  /// ```
  /// ControlRoute.of<DetailPage>(identifier: 'detail').path(path: (_) => 'node', query: (args) => {'id': args['id']});
  /// // refers to: /detail/node?id=1
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
  /// Returns a copy of this route with a new [identifier].
  /// {@endtemplate}
  ControlRoute named(String identifier) => _copyWith(
        identifier: identifier,
      );

  /// Creates a copy of this route with the given settings overridden.
  ControlRoute _copyWith({
    dynamic identifier,
    String? mask,
    RouteBuilderFactory? routeBuilder,
    RouteArgFactory? path,
    RouteArgFactory? query,
  }) =>
      ControlRoute._()
        ..identifier = identifier ?? this.identifier
        .._mask = mask ?? this._mask
        .._builder = _builder
        .._routeBuilder = routeBuilder ?? this._routeBuilder
        .._pathBuilder = path
        .._queryBuilder = query;

  /// Initializes a [RouteHandler] for this route with the given [navigator].
  RouteHandler navigator(RouteNavigator navigator) =>
      RouteHandler(navigator, this);

  /// Registers this route in the global [RouteStore].
  void register<T>() => _store.addRoute<T>(this);

  /// @{template route-store-get}
  /// Retrieves a [ControlRoute] from the global [RouteStore].
  ///
  /// A [Type] or [identifier] is required. Using a [Type] is recommended for type safety.
  /// The [RouteStore] is typically populated at app startup via [Control.initControl] or [ControlRoot].
  /// @{endtemplate}
  static ControlRoute? of<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return _store.getRoute<T>(identifier);
  }

  /// Returns the identifier of a route stored in the [RouteStore].
  /// See [RouteStore.routeIdentifier] for more information.
  static String? identifierOf<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return _store.getRoute<T>(identifier)?.identifier;
  }
}

/// A custom [PageRoute] that builds its transitions using a [RouteTransitionFactory].
class ControlRouteTransition extends PageRoute {
  /// The builder for the page's content.
  final WidgetBuilder builder;

  /// The factory for building the page's transition.
  final RouteTransitionFactory transition;

  /// The duration of the transition animation.
  final Duration duration;

  /// Creates a [PageRoute] with a custom [transition].
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

/// Provides setup information for a [ControlRouteTransition].
/// This is passed to the [RouteTransitionFactory] to build the transition.
class ControlRouteTransitionSetup {
  /// The animation for the route being pushed (the incoming route).
  final Animation<double> incomingAnimation;

  /// The animation for the route being popped (the outgoing route).
  final Animation<double> outgoingAnimation;

  /// The route that is being transitioned.
  final ControlRouteTransition route;

  /// The settings for the route.
  RouteSettings? get settings => route.settings;

  /// Whether this is the first route in the stack.
  bool get root => route.isFirst;

  /// Whether this route is the current route.
  bool get active => route.isActive;

  /// Whether the incoming animation is running forward.
  bool get foregroundIncoming =>
      (incomingAnimation.status == AnimationStatus.forward ||
          incomingAnimation.isCompleted) &&
      outgoingAnimation.isDismissed;

  /// Whether the incoming animation is running in reverse.
  bool get foregroundOutgoing =>
      (incomingAnimation.status == AnimationStatus.reverse ||
          incomingAnimation.isDismissed) &&
      outgoingAnimation.isDismissed;

  /// Whether the outgoing animation is running in reverse.
  bool get backgroundIncoming =>
      (outgoingAnimation.status == AnimationStatus.reverse ||
          outgoingAnimation.isDismissed) &&
      incomingAnimation.isCompleted;

  /// Whether the outgoing animation is running forward.
  bool get backgroundOutgoing =>
      (outgoingAnimation.status == AnimationStatus.forward ||
          outgoingAnimation.isCompleted) &&
      incomingAnimation.isCompleted;

  /// Whether the foreground (incoming) route is active.
  bool get foregroundActive => outgoingAnimation.isDismissed;

  /// Whether the background (outgoing) route is active.
  bool get backgroundActive => incomingAnimation.isCompleted;

  const ControlRouteTransitionSetup._(
    this.incomingAnimation,
    this.outgoingAnimation,
    this.route,
  );

  /// Creates a copy of this setup with curved animations.
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
