part of flutter_control;

/// Legacy - waiting for refactor.
/// Connects a [ControlRoute] with a [RouteNavigator] to execute navigation.
///
/// This class builds a [Route] from a [ControlRoute] and pushes it to the
/// navigator. It's designed for a single navigation action; do not reuse a
/// [RouteHandler] instance for multiple `openRoute` calls.
class RouteHandler {
  /// The navigator implementation to use for pushing routes.
  final RouteNavigator navigator;

  /// The route definition and provider.
  final ControlRoute routeProvider;

  /// A future that completes with the result of the route when it is popped.
  Future<dynamic>? _result;

  /// A future that completes with the result of the route when it is popped.
  Future<dynamic>? get result => _result;

  /// The actual [Route] instance that was built and pushed.
  Route<dynamic>? _route;

  /// The actual [Route] instance that was built and pushed.
  Route? get route => _route;

  /// Whether this handler has already been used to open a route.
  bool get isHandled => _result != null;

  /// The unique identifier of the route being handled.
  /// See [RouteStore.routeIdentifier] for more information.
  String? get identifier => routeProvider.identifier;

  /// Creates a [RouteHandler].
  ///
  /// This is typically not called directly but rather through [ControlRoute.navigator].
  RouteHandler(this.navigator, this.routeProvider);

  /// Creates a copy of this [RouteHandler] with a new [RouteBuilderFactory].
  ///
  /// {@macro route-route}
  RouteHandler viaRoute(RouteBuilderFactory builder) =>
      RouteHandler(navigator, routeProvider.viaRoute(builder));

  /// Creates a copy of this [RouteHandler] with a new transition.
  ///
  /// {@macro route-transition}
  RouteHandler viaTransition(RouteTransitionFactory transition) =>
      RouteHandler(navigator, routeProvider.viaTransition(transition));

  /// Creates a copy of this [RouteHandler] with a new path configuration.
  ///
  /// {@macro route-path}
  RouteHandler path(
          {InitFactory<dynamic>? name, InitFactory<dynamic>? query}) =>
      RouteHandler(navigator, routeProvider.path(path: name, query: query));

  /// Creates a copy of this [RouteHandler] with a new identifier.
  ///
  /// {@macro route-name}
  RouteHandler named(String identifier) =>
      RouteHandler(navigator, routeProvider.named(identifier));

  /// Builds the route and pushes it to the navigator.
  ///
  /// {@macro route-open}
  Future<dynamic> openRoute(
      {bool root = false, bool replacement = false, dynamic args}) {
    printDebug("open route: ${routeProvider.identifier} from $navigator");

    final route = navigator.openRoute(
      routeProvider.init(args: args),
      root: root,
      replacement: replacement,
    );

    return _result = route;
  }
}
