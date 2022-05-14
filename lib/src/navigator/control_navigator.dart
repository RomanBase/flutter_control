import 'package:flutter_control/core.dart';

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
    if (T != dynamic) {
      identifier = RouteStore.routeIdentifier<T>();
    }

    if (route != null) {
      predicate = (item) => item == route || item.isFirst;
    }

    if (identifier != null) {
      predicate = (item) => item.settings.name == identifier || item.isFirst;
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
        useRootNavigator: false);
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
