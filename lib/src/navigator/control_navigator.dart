part of flutter_control;

/// Providing basic type of navigation.
abstract class RouteNavigator {
  /// {@template route-open}
  /// Pushes a [Route] onto the navigation stack.
  ///
  /// [route] The route to push.
  /// [root] If `true`, pushes to the root navigator.
  /// [replacement] If `true`, replaces the current route.
  /// {@endtemplate}
  Future<dynamic> openRoute(Route route,
      {bool root = false, bool replacement = false});

  /// {@template route-root}
  /// Pushes a [Route] and removes all previous routes from the stack.
  /// {@endtemplate}
  Future<dynamic> openRoot(Route route);

  /// {@template route-back-to}
  /// Navigates back in the stack until a route matching the predicate is found.
  /// {@endtemplate}
  void backTo<T>({
    Route? route,
    String? identifier,
    bool Function(Route<dynamic>)? predicate,
    Route? open,
  });

  /// {@template route-back-root}
  /// Navigates back to the very first route in the navigation stack.
  /// {@endtemplate}
  void backToRoot({Route? open});

  /// {@template route-close}
  /// Pops the current route from the navigation stack.
  /// A [result] can be passed back to the previous route.
  /// {@endtemplate}
  bool close([dynamic result]);

  /// Removes a specific [route] from the navigator.
  bool closeRoute(Route route, [dynamic result]);
}

/// A concrete implementation of [RouteNavigator] that uses the standard
/// Flutter [Navigator] to perform navigation actions.
class ControlNavigator implements RouteNavigator {
  /// The build context used to find the [Navigator].
  final BuildContext context;

  /// Creates a [ControlNavigator] with a given [BuildContext].
  ControlNavigator(this.context);

  @protected
  NavigatorState getNavigator({bool root = false}) =>
      Navigator.of(context, rootNavigator: root);

  @override
  Future<dynamic> openRoute(Route route,
      {bool root = false, bool replacement = false}) {
    if (replacement) {
      return getNavigator().pushReplacement(route);
    } else {
      return getNavigator(root: root).push(route);
    }
  }

  @override
  Future openRoot(Route route) {
    return getNavigator().pushAndRemoveUntil(route, (route) => route.isFirst);
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
}
