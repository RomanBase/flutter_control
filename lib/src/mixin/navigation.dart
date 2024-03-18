part of flutter_control;

/// Mixin class to enable navigation for [ControlWidget]
extension RouteControlExt on CoreContext {
  ControlNavigator get navigator => ControlNavigator(this);

  /// Returns currently active [Route].
  /// [Route] is typically stored in [ControlArgHolder] during navigation handling and is passed as argument.
  /// If Route is not stored in arguments, closest Route from Navigation Stack is returned.
  Route? getActiveRoute() => args.get<Route>() ?? ModalRoute.of(this);

  /// {@macro route-store-get}
  RouteHandler? routeOf<T>([dynamic identifier]) => ControlRoute.of<T>(identifier)?.navigator(navigator);

  /// Initializes and returns [Route] via [RouteStore] and [RouteControl].
  ///
  /// {@macro route-store-get}
  Route? initRouteOf<T>({dynamic identifier, dynamic args}) => ControlRoute.of<T>(identifier)?.init(args: args);

  Future<dynamic> openRoute(Route route, {bool root = false, bool replacement = false}) => navigator.openRoute(route, root: root, replacement: replacement);

  Future<dynamic> openRoot(Route route) => navigator.openRoot(route);

  Future<dynamic> openDialog(WidgetBuilder builder, {bool root = true, dynamic type}) => navigator.openDialog(builder, root: root, type: type);

  void backTo<T>({
    Route? route,
    String? identifier,
    bool Function(Route<dynamic>)? predicate,
    Route? open,
  }) =>
      navigator.backTo<T>(
        route: route,
        identifier: identifier,
        predicate: predicate,
        open: open,
      );

  void backToRoot({Route? open}) => navigator.backToRoot(open: open);

  bool close(CoreContext context, [dynamic result]) {
    final route = getActiveRoute();

    if (route != null) {
      return closeRoute(route, result);
    } else {
      return navigator.close(result);
    }
  }

  bool closeRoute(Route route, [dynamic result]) => navigator.closeRoute(route, result);
}
