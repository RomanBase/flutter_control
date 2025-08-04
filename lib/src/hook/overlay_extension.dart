part of flutter_control;

extension RouteExtension on CoreContext {
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
