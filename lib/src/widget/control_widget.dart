import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

/// [ControlWidget] with just one init Controller.
abstract class SingleControlWidget<T extends ControlModel> extends ControlWidget {
  T get control => hasControl ? controls[0] : null;

  SingleControlWidget({Key key, dynamic args}) : super(key: key, args: args);

  @override
  List<ControlModel> initControls() => [initControl()];

  @protected
  T initControl() {
    T item = holder.get<T>();

    if (item == null) {
      item = Control.get<T>(args: holder.args);
    }

    return item;
  }
}

/// [ControlWidget] with no init Controllers.
abstract class BaseControlWidget extends ControlWidget {
  BaseControlWidget({Key key, dynamic args}) : super(key: key, args: args);

  @override
  List<ControlModel> initControls() => [];
}

/// Base [StatefulWidget] to cooperate with [BaseControl].
/// [BaseControl]
/// [StateControl]
///
/// [RouteControl] & [RouteControlProvider]
/// [RouteHandler] & [PageRouteProvider]
///
/// [ControlFactory]
/// [AppControl]
/// [BaseLocalization]
///
/// [ControlState]
/// [_ControlTickerState]
/// [_ControlSingleTickerState]
abstract class ControlWidget extends CoreWidget with LocalizationProvider implements Initializable, Disposable {
  /// Returns [true] if [State] is hooked and [WidgetControlHolder] is initialized.
  bool get isInitialized => holder.initialized;

  /// Returns [true] if Widget is active and [WidgetControlHolder] is not disposed.
  /// Widget is valid even when is not initialized yet.
  bool get isValid => holder.isValid;

  /// Widget's [State]
  /// [holder] - [onInitState]
  @protected
  ControlState get state => holder.state;

  /// List of Controllers passed during construction phase.
  /// [holder] - [initControls]
  @protected
  List<ControlModel> get controls => state?.controls;

  /// Instance of [ControlFactory].
  @protected
  ControlFactory get factory => Control.factory();

  bool get hasControl => controls != null && controls.length > 0;

  /// Default constructor
  ControlWidget({
    Key key,
    dynamic args,
  }) : super(key: key, args: args);

  /// Called during construction phase.
  /// Returned controllers will be notified during Widget/State initialization.
  @protected
  List<ControlModel> initControls() => holder.findControls();

  @override
  ControlState<ControlWidget> createState() => ControlState();

  /// Called during State initialization.
  /// All controllers (from [initControls]) are subscribed to this Widget and given State.
  @protected
  @mustCallSuper
  void onInitState(ControlState state) {
    assert(isInitialized);

    controls?.remove(null);
    controls?.forEach((control) {
      control.init(holder.args);
      control.subscribe(this);

      if (this is TickerProvider && control is TickerComponent) {
        control.provideTicker(this as TickerProvider);
      }

      if (control is StateControl) {
        state._subscribeStateNotifier(control as StateControl);
      }
    });
  }

  @protected
  void onInit(Map args) {
    super.onInit(args);

    controls?.forEach((control) {
      if (control is StateControl) {
        (control as StateControl).onStateInitialized();
      }
    });
  }

  /// Notifies [State] of this [Widget].
  void notifyState([dynamic state]) => this.state?.notifyState(state);

  /// Callback from [State] when state is notified.
  @protected
  void onStateChanged(dynamic state) {}

  /// Returns context of this widget or [root] context that is stored in [AppControl]
  BuildContext getContext({bool root: false}) => root ? Control.root()?.context ?? context : context;

  /// Returns value by given key or type.
  /// Look up in [controls] and [factory].
  /// Use [getArg] to look up in Widget's arguments.
  T getControl<T>({dynamic key, dynamic args}) => Control.resolve<T>(controls, key: key, args: args);

  /// [StatelessWidget.build]
  /// [StatefulWidget.build]
  @protected
  Widget build(BuildContext context);

  /// Disposes and removes all [controls].
  /// Controller can prevent disposing [BaseControl.preventDispose].
  @override
  @mustCallSuper
  void dispose() {
    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// Base State for ControlWidget and StateController
/// State is subscribed to Controller which notifies back about state changes.
class ControlState<U extends ControlWidget> extends CoreState<U> implements StateNotifier {
  List<ControlModel> controls;

  @override
  void initState() {
    super.initState();

    initControls();
    widget.onInitState(this);
  }

  void initControls() {
    controls = widget.initControls() ?? [];

    controls.forEach((control) {
      if (control is ReferenceCounter) {
        (control as ReferenceCounter).addReference(this);
      }
    });
  }

  @override
  void notifyState([dynamic state]) {
    if (mounted) {
      setState(() {
        widget.onStateChanged(state);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  /// Subscribes to [StateControl]
  void _subscribeStateNotifier(StateControl control) {
    control.addListener(notifyState);
  }

  /// Disposes and removes all [controls].
  /// Controller can prevent disposing [BaseControl.preventDispose].
  /// Then disposes Widget.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();

    if (controls != null) {
      controls.forEach((control) {
        if (control is StateControl) {
          (control as StateControl).removeListener(notifyState);
        }

        control.requestDispose(this);
      });
      controls.clear();
      controls = null;
    }

    widget.dispose();
  }
}

/// Mixin class to enable navigation for [ControlWidget]
mixin RouteControl on ControlWidget implements RouteNavigator {
  Route getActiveRoute() => getArg<Route>() ?? (context == null ? null : ModalRoute.of(context));

  @protected
  NavigatorState getNavigator({bool root: false}) {
    if (root && !Control.root().isInitialized) {
      return Navigator.of(context, rootNavigator: true);
    }

    return Navigator.of(getContext(root: root));
  }

  @override
  void init(Map args) {
    super.init(args);

    final route = getActiveRoute();
    if (route != null) {
      printDebug('${this.toString()} at route: ${route.settings.name}');
    }
  }

  RouteHandler routeOf<T>([dynamic identifier]) => ControlRoute.of<T>(identifier)?.navigator(this);

  Route initRouteOf<T>({dynamic identifier, dynamic args}) => ControlRoute.of<T>(identifier)?.init(args: args);

  @override
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false}) {
    if (replacement) {
      return getNavigator().pushReplacement(route);
    } else {
      return getNavigator(root: root).push(route);
    }
  }

  @override
  Future<dynamic> openRoot(Route route) {
    return getNavigator().pushAndRemoveUntil(route, (pop) => false);
  }

  @override
  Future<dynamic> openDialog(WidgetBuilder builder, {bool root: true, dynamic type}) async {
    return showDialog(context: getContext(root: root), builder: (context) => builder(context), useRootNavigator: false);
  }

  void backTo({Route route, String identifier, bool Function(Route<dynamic>) predicate}) {
    if (route != null) {
      getNavigator().popUntil((item) => item == route);
    }

    if (identifier != null) {
      getNavigator().popUntil((item) => item.settings.name == identifier);
    }

    if (predicate != null) {
      getNavigator().popUntil(predicate);
    }
  }

  @override
  void backToRoot() {
    getNavigator().popUntil((route) => route.isFirst);
  }

  @override
  bool close([dynamic result]) {
    final route = getActiveRoute();

    if (route != null) {
      return closeRoute(route, result);
    } else {
      final navigator = getNavigator();

      if (navigator.canPop()) {
        getNavigator().pop(result);
        return true;
      }

      return false;
    }
  }

  @override
  bool closeRoute(Route route, [dynamic result]) {
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
