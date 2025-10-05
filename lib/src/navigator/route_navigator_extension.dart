part of flutter_control;

/// Mixin class to enable navigation for [ControlWidget]
extension RouteNavigatorExtension on BuildContext {
  ControlNavigator get navigator => ControlNavigator(this);

  /// Returns currently active [Route].
  /// [Route] is typically stored in [ControlArgHolder] during navigation handling and is passed as argument.
  /// If Route is not stored in arguments, closest Route from Navigation Stack is returned.
  Route? getActiveRoute() =>
      (this is CoreContext ? (this as CoreContext).args.get<Route>() : null) ??
      ModalRoute.of(this);

  /// {@macro route-store-get}
  RouteHandler? routeOf<T>([dynamic identifier]) =>
      ControlRoute.of<T>(identifier)?.navigator(navigator);

  /// Initializes and returns [Route] via [RouteStore] and [RouteControl].
  ///
  /// {@macro route-store-get}
  Route? initRouteOf<T>({dynamic identifier, dynamic args}) =>
      ControlRoute.of<T>(identifier)?.init(args: args);

  Future<dynamic> openRoute(Route route,
          {bool root = false, bool replacement = false}) =>
      navigator.openRoute(route, root: root, replacement: replacement);

  Future<dynamic> openRoot(Route route) => navigator.openRoot(route);

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

  bool close([dynamic result]) {
    final route = getActiveRoute();

    if (route != null) {
      return closeRoute(route, result);
    } else {
      return navigator.close(result);
    }
  }

  bool closeRoute(Route route, [dynamic result]) =>
      navigator.closeRoute(route, result);

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

  bool get atRoot {
    final route = ModalRoute.of(this);

    return route != null && route.isFirst;
  }
}
