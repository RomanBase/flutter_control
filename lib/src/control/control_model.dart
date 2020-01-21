import 'dart:async';

import 'package:flutter_control/core.dart';

/// Standard initialization of object right after constructor.
abstract class Initializable {
  /// Is typically called right after constructor.
  void init(Map args) {}
}

/// Base abstract class for communication between Controller - [StateControl] and [State].
/// Controller can notify State about changes.
/// This class needs to be implemented in State.
abstract class StateNotifier {
  /// Notifies about state changes and requests State to rebuild UI.
  void notifyState([dynamic state]);
}

/// Super base model to use with [ControlWidget]
/// [init] -> [onInit] is called during Widget's construction phase.
/// [subscribe] is called during State's init phase.
///
/// [BaseControl]
/// [BaseModel]
///
/// Extend this class to create custom controllers and models.
///
/// Mixin your model with [LocalizationProvider] to enable localization.
class ControlModel with DisposeHandler, Disposer implements Initializable {
  /// returns instance of [ControlFactory] if available.
  /// nullable
  ControlFactory get factory => Control.factory();

  @override
  void init(Map args) {}

  /// Used to subscribe interface/handler/notifier etc.
  /// Can be called multiple times with different objects!
  void subscribe(dynamic object) {}

  /// Called during State initialization.
  /// Check [TickerControl] mixin.
  void onTickerInitialized(TickerProvider ticker) {}

  @override
  void dispose() {
    super.dispose();

    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// Base controller to use with [ControlWidget]
/// [init] -> [onInit] is called during Widget's construction phase.
/// [subscribe] is called during State's init phase.
///
/// [AppControl]
/// [ControlFactory]
///
/// Mixin your model with [LocalizationProvider] to enable localization.
class BaseControl extends ControlModel {
  /// init check.
  bool _isInitialized = false;

  /// return true if init function was called before.
  bool get isInitialized => _isInitialized;

  /// prevent multiple times init and [onInit] will be called just once
  bool preventMultiInit = true;

  /// Set [preventMultiInit] enable multi init / re-init
  @override
  @mustCallSuper
  BaseControl init([Map args]) {
    if (isInitialized && preventMultiInit) {
      printDebug('controller is already initialized: ${this.runtimeType.toString()}');
      return this;
    }

    _isInitialized = true;
    onInit(args);

    return this;
  }

  /// Is typically called right after constructor or when init is available.
  /// In most of times [Widget] or [State] isn't ready yet.
  /// check [init] and [preventMultiInit]
  void onInit(Map args) {}

  /// Used to reload Controller.
  /// Called by [NavigatorStack] when page is reselected.
  Future<void> reload() async {}

  /// Typically is this method called during State disable phase.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    _isInitialized = false;
  }
}

mixin StateControl on ControlModel implements StateNotifier, Listenable {
  /// Notify listeners.
  final _notifier = BaseNotifier();

  /// Called during State initialization.
  void onStateInitialized() {}

  @override
  void notifyState([dynamic state]) => _notifier.notifyState(state);

  void subscribeStateNotifier(VoidCallback action) => _notifier.addListener(action);

  void cancelStateNotifier(VoidCallback action) => _notifier.removeListener(action);

  @override
  void addListener(VoidCallback listener) => subscribeStateNotifier(listener);

  @override
  void removeListener(VoidCallback listener) => cancelStateNotifier(listener);

  @override
  void dispose() {
    super.dispose();

    _notifier.dispose();
  }
}

/// Mixin for [BaseControl]
/// Enables navigation from Controller.
///
/// [ControlWidget] with [RouteNavigator]
/// [DirectNavigator]
/// [RouteHandler] & [PageRouteProvider]
mixin RouteControl on ControlModel {
  /// Implementation of [DirectNavigator] where [Navigator] is used.
  DirectNavigator _navigator;

  /// Check if is [DirectNavigator] valid.
  bool get isNavigatorAvailable => _navigator != null;

  /// Subscribes [DirectNavigator] for later user.
  @override
  @mustCallSuper
  void subscribe(dynamic object) {
    super.subscribe(object);

    if (object is DirectNavigator) {
      _navigator = object;
    }
  }

  RouteHandler routeOf<T>([dynamic identifier]) => ControlRoute.of<T>(identifier)?.navigator(_navigator);

  /// [DirectNavigator.openRoute].
  /// [RouteHandler] -> [PageRouteProvider]
  RouteHandler openRoute(
    ControlRoute route, {
    bool root: false,
    bool replacement: false,
    dynamic args,
    FutureOr<dynamic> result(dynamic value),
  }) {
    final handler = RouteHandler(_navigator, route);

    final future = handler.openRoute(root: root, replacement: replacement, args: args);

    if (result != null) {
      future.then(result);
    }

    return handler;
  }

  /// [DirectNavigator.openRoot].
  /// [RouteHandler] -> [PageRouteProvider]
  RouteHandler openRoot(
    ControlRoute route, {
    dynamic args,
    FutureOr<dynamic> result(dynamic value),
  }) {
    final handler = RouteHandler(_navigator, route);

    final future = handler.openRoot(args: args);

    if (result != null) {
      future.then(result);
    }

    return handler;
  }

  /// [DirectNavigator.openDialog].
  /// [RouteHandler] -> [PageRouteProvider]
  Future<dynamic> openDialog(
    ControlRoute route, {
    bool root: false,
    DialogType type: DialogType.popup,
    dynamic args,
  }) {
    return RouteHandler(_navigator, route).openDialog(root: root, type: type, args: args);
  }

  /// [DirectNavigator.close].
  void close([dynamic result]) => _navigator?.close(result);

  /// [DirectNavigator.backTo].
  void backTo({
    Route route,
    String identifier,
    bool Function(Route<dynamic>) predicate,
  }) =>
      _navigator?.backTo(
        route: route,
        identifier: identifier,
        predicate: predicate,
      );

  /// [DirectNavigator.openRoot].
  void backToRoot() => _navigator?.backToRoot();

  /// Disables [DirectNavigator].
  @override
  void dispose() {
    super.dispose();

    _navigator = null;
  }
}
