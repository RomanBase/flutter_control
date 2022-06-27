part of flutter_control;

/// Providing basic type of navigation.
abstract class RouteNavigator {
  /// {@template route-open}
  /// Pushes route into current Navigator.
  /// [route] - specific route: type, settings, transition etc.
  /// [root] - pushes route into root Navigator - onto top of everything.
  /// [replacement] - pushes route as replacement of current route.
  /// {@endtemplate}
  Future<dynamic> openRoute(Route route,
      {bool root: false, bool replacement: false});

  /// {@template route-root}
  /// Clears current [Navigator] and opens new [Route].
  /// {@endtemplate}
  Future<dynamic> openRoot(Route route);

  /// {@template route-dialog}
  /// Opens specific dialog based on given [type]
  /// Be default opens simple pop-up dialog.
  /// {@endtemplate}
  Future<dynamic> openDialog(WidgetBuilder builder,
      {bool root: true, dynamic type});

  /// {@template route-back-root}
  /// Goes back in navigation stack until first [Route].
  /// {@endtemplate}
  void backToRoot({Route? open});

  /// {@template route-back-to}
  /// Goes back in navigation stack until [Route] found.
  /// {@endtemplate}
  void backTo<T>({
    Route? route,
    String? identifier,
    bool Function(Route<dynamic>)? predicate,
    Route? open,
  });

  /// {@template route-close}
  /// Pops [Route] from navigation stack.
  /// result is send back to parent.
  /// {@endtemplate}
  bool close([dynamic result]);

  /// Removes given [route] from navigator.
  bool closeRoute(Route route, [dynamic result]);
}

class ControlNavigator implements RouteNavigator {
  final BuildContext context;

  ControlNavigator(this.context);

  BuildContext getContext({bool root: false}) =>
      root ? ControlScope.root.context ?? context : context;

  @protected
  NavigatorState getNavigator({bool root: false}) {
    if (root && !ControlScope.root.isInitialized) {
      return Navigator.of(context, rootNavigator: true);
    }

    return Navigator.of(getContext(root: root));
  }

  @override
  void backTo<T>({
    Route? route,
    String? identifier,
    bool Function(Route<dynamic>)? predicate,
    Route? open,
  }) {
    if (predicate == null) {
      if (T != dynamic) {
        identifier = RouteStore.routeIdentifier<T>(identifier);
      }

      if (route != null) {
        predicate = (item) => item == route || item.isFirst;
      }

      if (identifier != null) {
        predicate = (item) => item.settings.name == identifier || item.isFirst;
      }
    }

    if (predicate != null) {
      if (open != null) {
        getNavigator().pushAndRemoveUntil(open, predicate);
      } else {
        getNavigator().popUntil(predicate);
      }
    }
  }

  @override
  void backToRoot({Route? open}) => backTo(
        predicate: (route) => route.isFirst,
        open: open,
      );

  @override
  bool close([result]) {
    final navigator = getNavigator();

    if (navigator.canPop()) {
      getNavigator().pop(result);
      return true;
    }

    return false;
  }

  @override
  bool closeRoute(Route route, [result]) {
    if (route.isCurrent) {
      final navigator = getNavigator();

      if (navigator.canPop()) {
        getNavigator().pop(result);
        return true;
      }

      return false;
    } else {
      // ignore: invalid_use_of_protected_member
      route.didComplete(result);
      getNavigator().removeRoute(route);
      return true;
    }
  }

  @override
  Future openDialog(builder, {bool root = true, dynamic type}) {
    return showDialog(
      context: getContext(root: root),
      builder: (context) => builder(context),
      useRootNavigator: false,
    );
  }

  @override
  Future openRoot(Route route) {
    return getNavigator().pushAndRemoveUntil(route, (route) => route.isFirst);
  }

  @override
  Future openRoute(Route route, {bool root = false, bool replacement = false}) {
    if (replacement) {
      return getNavigator().pushReplacement(route);
    } else {
      return getNavigator(root: root).push(route);
    }
  }
}
