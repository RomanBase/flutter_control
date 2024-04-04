part of flutter_control;

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
  Route<dynamic>? _route;

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
  RouteHandler viaRoute(RouteBuilderFactory builder) => RouteHandler(navigator, routeProvider.viaRoute(builder));

  /// Creates copy of [RouteHandler] with given transition.
  ///
  /// @{macro route-transition}
  RouteHandler viaTransition(RouteTransitionFactory transition) => RouteHandler(navigator, routeProvider.viaTransition(transition));

  /// Creates copy of [RouteHandler] with given path name.
  ///
  /// @{macro route-path}
  RouteHandler path({InitFactory<dynamic>? name, InitFactory<dynamic>? query}) => RouteHandler(navigator, routeProvider.path(path: name, query: query));

  /// Creates copy of [RouteHandler] with given identifier.
  ///
  /// @{macro route-named}
  RouteHandler named(String identifier) => RouteHandler(navigator, routeProvider.named(identifier));

  /// @{macro route-open}
  Future<dynamic> openRoute({bool root = false, bool replacement = false, dynamic args}) {
    printDebug("open route: ${routeProvider.identifier} from $navigator");

    final route = navigator.openRoute(
      routeProvider.init(args: args),
      root: root,
      replacement: replacement,
    );

    return _result = route;
  }
}
