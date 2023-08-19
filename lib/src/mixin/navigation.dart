part of flutter_control;

/// Mixin class to enable navigation for [ControlWidget]
mixin RouteControl on CoreWidget implements RouteNavigator {
  ControlNavigator get navigator => ControlNavigator(context!);

  @override
  void init(Map args) {
    super.init(args);

    final route = getActiveRoute();
    if (route != null) {
      printDebug('${this.toString()} at route: ${route.settings.name}');
    }
  }

  /// Returns [RouteControl] of closest [ControlState] that belongs to [ControlWidget] / [SingleControlWidget] / [BaseControlWidget] with [RouteControl] mixin.
  ///
  /// Typically not used directly, but via navigator or route ancestors.
  ///
  /// Check [findNavigator] for direct [Route] navigation.
  /// Check [findRouteOf] for direct [RouteHandler] access.
  static RouteControl? _findAncestor(BuildContext context) {
    final state = context.findAncestorStateOfType<ControlState>();
    final widget = state?.widget;

    if (widget == null) {
      return null;
    }

    if (widget is RouteControl) {
      return widget as RouteControl;
    }

    return state == null ? null : _findAncestor(state.context);
  }

  /// Returns [RouteNavigator] of closest [ControlState] that belongs to [ControlWidget] / [SingleControlWidget] / [BaseControlWidget] with [RouteControl] mixin.
  static RouteNavigator? findNavigator(BuildContext context) =>
      _findAncestor(context);

  /// Returns [RouteHandler] for given Route of closest [ControlState] that belongs to [ControlWidget] / [SingleControlWidget] / [BaseControlWidget] with [RouteControl] mixin.
  ///
  /// {@macro route-store-get}
  static RouteHandler? findRouteOf<T>(BuildContext context,
          [dynamic identifier]) =>
      _findAncestor(context)?.routeOf<T>(identifier);

  /// Returns currently active [Route].
  /// [Route] is typically stored in [ControlArgHolder] during navigation handling and is passed as argument.
  /// If Route is not stored in arguments, closest Route from Navigation Stack is returned.
  Route? getActiveRoute() =>
      getArg<Route>() ?? (context == null ? null : ModalRoute.of(context!));

  /// {@macro route-store-get}
  RouteHandler? routeOf<T>([dynamic identifier]) =>
      ControlRoute.of<T>(identifier)?.navigator(this);

  /// Initializes and returns [Route] via [RouteStore] and [RouteControl].
  ///
  /// {@macro route-store-get}
  Route? initRouteOf<T>({dynamic identifier, dynamic args}) =>
      ControlRoute.of<T>(identifier)?.init(args: args);

  @override
  Future<dynamic> openRoute(Route route,
          {bool root = false, bool replacement = false}) =>
      navigator.openRoute(route, root: root, replacement: replacement);

  @override
  Future<dynamic> openRoot(Route route) => navigator.openRoot(route);

  @override
  Future<dynamic> openDialog(WidgetBuilder builder,
          {bool root = true, dynamic type}) =>
      navigator.openDialog(builder, root: root, type: type);

  @override
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

  @override
  void backToRoot({Route? open}) => navigator.backToRoot(open: open);

  @override
  bool close([dynamic result]) {
    final route = getActiveRoute();

    if (route != null) {
      return closeRoute(route, result);
    } else {
      return navigator.close(result);
    }
  }

  @override
  bool closeRoute(Route route, [dynamic result]) =>
      navigator.closeRoute(route, result);
}
