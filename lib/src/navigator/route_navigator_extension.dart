part of flutter_control;

/// An extension on [BuildContext] that provides a set of convenience methods
/// for navigation, making it easy to perform routing actions from anywhere
/// in the widget tree.
extension RouteNavigatorExtension on BuildContext {
  /// Provides a [ControlNavigator] instance for the current context.
  ControlNavigator get navigator => ControlNavigator(this);

  /// Returns the currently active [Route].
  ///
  /// It first attempts to find the route in the [ControlArgHolder] (passed during navigation),
  /// and falls back to `ModalRoute.of(this)`.
  Route? getActiveRoute() =>
      (this is CoreContext ? (this as CoreContext).args.get<Route>() : null) ??
      ModalRoute.of(this);

  /// {@macro route-store-get}
  ///
  /// Returns a [RouteHandler] for the found route, allowing for fluent navigation calls.
  RouteHandler? routeOf<T>([dynamic identifier]) =>
      ControlRoute.of<T>(identifier)?.navigator(navigator);

  /// Initializes and returns a [Route] from the [RouteStore] without pushing it.
  ///
  /// {@macro route-store-get}
  Route? initRouteOf<T>({dynamic identifier, dynamic args}) =>
      ControlRoute.of<T>(identifier)?.init(args: args);

  /// {@macro route-open}
  Future<dynamic> openRoute(Route route,
          {bool root = false, bool replacement = false}) =>
      navigator.openRoute(route, root: root, replacement: replacement);

  /// {@macro route-root}
  Future<dynamic> openRoot(Route route) => navigator.openRoot(route);

  /// {@macro route-back-to}
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

  /// {@macro route-back-root}
  void backToRoot({Route? open}) => navigator.backToRoot(open: open);

  /// Closes the current active route.
  ///
  /// A [result] can be passed back to the previous route.
  /// This method is safer than calling `navigator.pop()` directly as it
  /// handles finding the correct route to close.
  bool close([dynamic result]) {
    final route = getActiveRoute();

    if (route != null) {
      return closeRoute(route, result);
    } else {
      return navigator.close(result);
    }
  }

  /// Closes a specific [route].
  bool closeRoute(Route route, [dynamic result]) =>
      navigator.closeRoute(route, result);

  /// A convenience method to open a new route with a simple [WidgetBuilder].
  ///
  /// This is useful for routes that are not pre-registered in the [RouteStore].
  Future<dynamic> openView({
    required WidgetBuilder builder,
    dynamic identifier,
    bool root = false,
    bool replacement = false,
    dynamic args,
    RouteBuilderFactory? route,
    RouteTransitionFactory? transition,
  }) {
    ControlRoute cr =
        ControlRoute.build(identifier: identifier ?? '#', builder: builder);

    if (route != null) {
      cr = cr.viaRoute(route);
    } else if (transition != null) {
      cr = cr.viaTransition(transition);
    }

    return cr
        .navigator(navigator)
        .openRoute(root: root, replacement: replacement, args: args);
  }

  /// Opens a pre-registered page from the [RouteStore].
  ///
  /// Throws an error if the route is not found.
  Future<dynamic> openPage<T>({
    dynamic identifier,
    bool root = false,
    bool replacement = false,
    dynamic args,
    RouteBuilderFactory? route,
    RouteTransitionFactory? transition,
  }) {
    RouteHandler? rh = routeOf<T>(identifier);

    if (rh == null) {
      throw 'Route not found: $T, $identifier';
    }

    if (route != null) {
      rh = rh.viaRoute(route);
    }

    if (transition != null) {
      rh = rh.viaTransition(transition);
    }

    return rh.openRoute(root: root, replacement: replacement, args: args);
  }

  /// Checks if the current route is the first route in the navigation stack.
  bool get atRoot {
    final route = ModalRoute.of(this);

    return route != null && route.isFirst;
  }
}
