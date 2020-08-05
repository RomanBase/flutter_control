import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

/// Standard initialization of object right after constructor.
abstract class Initializable {
  /// {@template init-object}
  /// Init is typically called right after constructor by framework.
  /// [args] - Arguments passed from parent or through Factory.
  /// {@endtemplate}
  void init(Map args) {}
}

/// Basic interface for communication between Control (eg. [StateControl]) and [State].
abstract class StateNotifier {
  /// Notifies about state changes and requests State to rebuild UI.
  void notifyState([dynamic state]);
}

/// {@template control-model}
/// Base class to use with [CoreWidget] - specifically [ControlWidget] and [StateboundWidget].
/// Logic part that handles Streams, loading, data, etc.
/// Init [args] helps to pass reference of other used Controls and objects.
///
/// Extend this class to create custom controls and models.
/// {@endtemplate}
class ControlModel with DisposeHandler implements Initializable {
  @override
  void init(Map args) {}

  //TODO: revisit
  /// Used to subscribe interface/handler/notifier etc.
  /// Can be called multiple times with different objects!
  /// Will be revisited - unused from v1.1.
  void subscribe(dynamic object) {}

  @override
  void dispose() {
    super.dispose();

    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// Extended version of [ControlModel]. Mainly used for complex Widgets as Pages or to separate/reuse logic.
///
/// @{macro control-model}
class BaseControl extends ControlModel {
  /// Init check.
  bool _isInitialized = false;

  /// Return 'true' if init function was called before.
  bool get isInitialized => _isInitialized;

  /// Prevents multiple initialization and [onInit] will be called just once.
  bool preventMultiInit = true;

  /// {@macro init-object}
  /// Set [preventMultiInit] to enable multi init / re-init
  @override
  @mustCallSuper
  void init(Map args) {
    if (isInitialized && preventMultiInit) {
      printDebug(
          'controller is already initialized: ${this.runtimeType.toString()}');
      return;
    }

    _isInitialized = true;
    onInit(args);
  }

  /// Is typically called once and shortly after constructor.
  /// In most of times [Widget] or [State] isn't ready yet.
  /// [preventMultiInit] is enabled by default and prevents multiple calls of this function.
  /// [args] input arguments passed from parent or Factory.
  void onInit(Map args) {}

  /// Reload model and data.
  Future<void> reload() async {}

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    _isInitialized = false;
  }
}

/// Lightweight version of [ControlModel]. Mainly used for simple Widgets as Items in dynamic List or to separate/reuse Logic, also to prevent dispose, because [BaseModel] overrides [preferSoftDispose].
/// [dispose] must be called manually !
///
/// @{macro control-model}
class BaseModel extends ControlModel {
  @override
  bool preferSoftDispose = true;

  /// Default constructor.
  BaseModel();
}

/// Mixin for [ControlModel] to pass [TickerProvider] from [CoreWidget] - [ControlWidget] or [StateboundWidget].
/// Enables to construct [AnimationController] and control animations.
///
/// Typically used as private [ControlModel] next to Widget class. This solution helps to separate animation/UI logic, actual business logic and pure UI.
///
/// Also Widget must use [TickerControl] or [SingleTickerControl] to enable vsync provider or pass [TickerProvider] from other place by calling [provideTicker].
mixin TickerComponent on ControlModel {
  /// Active provider. In fact provider can be used from different [ControlModel].
  TickerProvider _ticker;

  /// Returns active [TickerProvider] provided by Widget or passed by other Control.
  @protected
  TickerProvider get ticker => _ticker;

  /// Checks if [TickerProvider] is set.
  bool get isTickerAvailable => _ticker != null;

  /// Sets vsync. Called by framework during [State] initialization when used with [CoreWidget] and [TickerControl].
  void provideTicker(TickerProvider ticker) {
    _ticker = ticker;

    onTickerInitialized(ticker);
  }

  /// Callback after [provideTicker] is executed.
  /// Serves to created [AnimationController] and to set initial animation state.
  void onTickerInitialized(TickerProvider ticker);

  @override
  void dispose() {
    super.dispose();

    _ticker = null;
  }
}

/// Mixin to control [State] of [StateboundWidget] or [ControlWidget].
/// Also usable with [NotifierBuilder].
mixin StateControl on Disposable implements StateNotifier, Listenable {
  /// Notifier and state holder.
  final _notifier = BaseNotifier();

  /// Returns state as [Listenable].
  /// Prevent to use directly, check [addListener], [removeListener] and [notifyState].
  ValueListenable get state => _notifier;

  /// Called right after [State.initState] and whenever dependency of state changes [State.didChangeDependencies].
  void onStateInitialized() {}

  @override
  void notifyState([dynamic state]) => _notifier.value = state;

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);

  @override
  void dispose() {
    super.dispose();

    _notifier.dispose();
  }
}

/// Mixin for [ControlModel] to pass [RouteNavigator] from [CoreWidget] - [ControlWidget] or [StateboundWidget].
/// Creates bridge to UI where [Navigator] is implemented and enables navigation from Logic class.
///
/// Check [ControlRoute] and [RouteStore] to work with routes.
///
/// Also Widget must use [RouteControl] to enable navigator and [RouteHandler].
mixin RouteControlProvider on ControlModel {
  /// Implementation of [RouteNavigator].
  RouteNavigator _navigator;

  /// Checks if [RouteNavigator] is valid.
  bool get isNavigatorAvailable => _navigator != null;

  //TODO: rework
  /// Subscribes [RouteNavigator] for later user.
  @override
  @mustCallSuper
  void subscribe(dynamic object) {
    super.subscribe(object);

    if (object is RouteNavigator) {
      _navigator = object;
    }
  }

  /// {@macro route-store-get}
  RouteHandler routeOf<T>([dynamic identifier]) =>
      ControlRoute.of<T>(identifier)?.navigator(_navigator);

  /// {@macro route-open}
  RouteHandler openRoute(
    ControlRoute route, {
    bool root: false,
    bool replacement: false,
    dynamic args,
    FutureOr<dynamic> result(dynamic value),
  }) {
    final handler = RouteHandler(_navigator, route);

    final future =
        handler.openRoute(root: root, replacement: replacement, args: args);

    if (result != null) {
      future.then(result);
    }

    return handler;
  }

  /// {@macro route-root}
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

  /// {@macro route-dialog}
  Future<dynamic> openDialog(
    ControlRoute route, {
    bool root: false,
    dynamic type,
    dynamic args,
  }) {
    return RouteHandler(_navigator, route)
        .openDialog(root: root, type: type, args: args);
  }

  /// {@macro route-close}
  bool close([dynamic result]) => _navigator?.close(result);

  /// {@macro route-back-to}
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

  /// {@macro route-back-root}
  void backToRoot() => _navigator?.backToRoot();

  @override
  void dispose() {
    super.dispose();

    _navigator = null;
  }
}
