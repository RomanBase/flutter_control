import 'dart:async';

import 'package:flutter/foundation.dart';
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
class ControlModel with DisposeHandler /*, Disposer*/ implements Initializable {
  /// returns instance of [ControlFactory] if available.
  /// nullable
  ControlFactory get factory => Control.factory();

  @override
  void init(Map args) {}

  /// Used to subscribe interface/handler/notifier etc.
  /// Can be called multiple times with different objects!
  /// Will be revisited - unused from v1.0.
  void subscribe(dynamic object) {}

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
  void init(Map args) {
    if (isInitialized && preventMultiInit) {
      printDebug('controller is already initialized: ${this.runtimeType.toString()}');
      return;
    }

    _isInitialized = true;
    onInit(args);
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

/// Lightweight version of Controller. Mainly used for Items in dynamic List or to separate/reuse Logic.
/// Mixin your model with [LocalizationProvider] to enable localization.
class BaseModel extends ControlModel {
  @override
  bool preferSoftDispose = true;

  /// Default constructor.
  BaseModel();
}

mixin TickerComponent on ControlModel {
  TickerProvider _ticker;

  @protected
  TickerProvider get ticker => _ticker;

  bool get isTickerAvailable => _ticker != null;

  void provideTicker(TickerProvider ticker) {
    _ticker = ticker;

    onTickerInitialized(ticker);
  }

  /// Called during State initialization.
  /// Check [TickerControl] mixin.
  void onTickerInitialized(TickerProvider ticker);

  @override
  void dispose() {
    super.dispose();

    _ticker = null;
  }
}

mixin StateControl on Disposable implements StateNotifier, Listenable {
  /// Notify listeners.
  final _notifier = BaseNotifier();

  ValueListenable get state => _notifier;

  /// Called right after [State.initState] and whenever dependency of state changes [State.didChangeDependencies].
  void onStateInitialized() {}

  @override
  void notifyState([dynamic state]) => _notifier.value = state;

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _notifier.removeListener(listener);

  @override
  void dispose() {
    super.dispose();

    _notifier.dispose();
  }
}

/// Mixin for [ControlModel]
/// Enables navigation from Controller.
///
/// [ControlWidget] with [RouteControl]
/// [RouteNavigator]
/// [RouteHandler] & [PageRouteProvider]
mixin RouteControlProvider on ControlModel {
  /// Implementation of [RouteNavigator] where [Navigator] is used.
  RouteNavigator _navigator;

  /// Check if is [RouteNavigator] valid.
  bool get isNavigatorAvailable => _navigator != null;

  /// Subscribes [RouteNavigator] for later user.
  @override
  @mustCallSuper
  void subscribe(dynamic object) {
    super.subscribe(object);

    if (object is RouteNavigator) {
      _navigator = object;
    }
  }

  RouteHandler routeOf<T>([dynamic identifier]) => ControlRoute.of<T>(identifier)?.navigator(_navigator);

  /// [RouteNavigator.openRoute].
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

  /// [RouteNavigator.openRoot].
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

  /// [RouteNavigator.openDialog].
  /// [RouteHandler] -> [PageRouteProvider]
  Future<dynamic> openDialog(
    ControlRoute route, {
    bool root: false,
    dynamic type,
    dynamic args,
  }) {
    return RouteHandler(_navigator, route).openDialog(root: root, type: type, args: args);
  }

  /// [RouteNavigator.close].
  bool close([dynamic result]) => _navigator?.close(result);

  /// [RouteNavigator.backTo].
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

  /// [RouteNavigator.openRoot].
  void backToRoot() => _navigator?.backToRoot();

  /// Disables [RouteNavigator].
  @override
  void dispose() {
    super.dispose();

    _navigator = null;
  }
}
