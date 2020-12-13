import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

abstract class BaseControlWidget extends CoreWidget {
  Widget build(BuildContext context);

  @override
  State<StatefulWidget> createState() => BaseControlState();

  BaseControlWidget({Key key}) : super(key: key);
}

class BaseControlState extends CoreState<BaseControlWidget> {
  @override
  Widget build(BuildContext context) => widget.build(context);
}

/// [ControlWidget] with one main [ControlModel].
/// Required [ControlModel] is returned by [initControl] - override this functions if Model is not in [args] or [ControlFactory] can't return it.
///
/// {@macro control-widget}
abstract class SingleControlWidget<T extends ControlModel> extends ControlWidget {
  /// Initialized [ControlModel], This objects is stored in [controls] List at first place.
  T get control => hasControl ? controls[0] : null;

  /// If given [args] contains [ControlModel] of requested [Type], it will be used as [control], otherwise [Control.get] will provide requested [ControlModel].
  SingleControlWidget({Key key, dynamic args}) : super(key: key, args: args);

  @override
  List<ControlModel> initControls() {
    final control = initControl();

    if (autoMountControls) {
      final controls = holder.findControls();

      if (controls.contains(control)) {
        controls.remove(control);
      }

      controls.insert(0, control);

      return controls;
    }

    if (control == null) {
      printDebug('NULL Control - $this');
    }

    return [control];
  }

  /// Tries to find or construct instance of requested [Type].
  /// If init [args] contains [ControlModel] of requested [Type], it will be used as [control], otherwise [Control.get] will provide requested [ControlModel].
  /// Check [initControls] for more dependency possibilities.
  /// Returns [ControlModel] of given [Type].
  @protected
  T initControl() => getControl<T>();
}

/// {@template control-widget}
/// [ControlWidget] maintains larger UI parts of App (Pages or complex Widgets). Widget is created with default [ControlState] to correctly reflect lifecycle of [Widget] to Models and Controls. So there is no need to create custom [State].
/// Widget will [init] all containing Models and pass arguments to them.
/// [ControlWidget] is 'immutable' so all logic parts (even UI logic and animations) must be handled outside. This helps truly separate all 'code' from pure UI (also helps to reuse this code).
///
/// This Widget comes with few [mixin] classes:
///   - [RouteControl] to abstract navigation and easily pass arguments and init other Pages.
///   - [TickerControl] and [SingleTickerControl] to create [Ticker] and provide access to [vsync]. Then use [ControlModel] with [TickerComponent] to get access to [TickerProvider].
///
/// Typically one or more [ControlModel] objects handles all logic for [ControlWidget]. This solution helps to separate even [Animation] from Business Logic and UI Widgets part.
/// And comes with [LocalizationProvider] to use [BaseLocalization] without standard delegate solution.
///
/// [ControlWidget] - Basic Widget with manual [ControlModel] initialization.
/// [SingleControlWidget] - Focused to single [ControlModel]. But still can handle multiple Controls.
/// [MountedControlWidget] - Automatically uses all [ControlModel]s passed to Widget.
///
/// Also check [StateboundWidget] an abstract Widget focused to build smaller Widgets controlled by [StateControl] and [BaseModel].
/// {@endtemplate}
abstract class ControlWidget extends CoreWidget with LocalizationProvider implements Initializable, Disposable, StateNotifier {
  /// Widget's [State]
  /// It's available just after [ControlState] is initialized.
  @protected
  ControlState get state => holder.state;

  /// List of [ControlModel]s initialized via [initControls].
  /// Set [autoMountControls] to automatically init all Models passed through [args].
  @protected
  List<ControlModel> get controls => state?.controls;

  /// Checks if [controls] is not empty.
  bool get hasControl => controls != null && controls.isNotEmpty;

  /// Checks [args] and returns all [ControlModel]s during [initControls] and these Models will be initialized by this Widget.
  /// By default set to 'false'.
  bool get autoMountControls => false;

  /// Focused to handle Pages or complex Widgets.
  /// [args] - Arguments passed to this Widget and also to [ControlModel]s.
  /// Check [SingleControlWidget] and [MountedControlWidget] to automatically handle input Controls.
  ControlWidget({
    Key key,
    dynamic args,
  }) : super(key: key, args: args);

  /// This is a place where to fill all required [ControlModel]s for this Widget.
  /// Called during Widget/State initialization phase.
  ///
  /// Dependency Injection possibilities:
  /// [holder.findControls] - Returns [ControlModel]s from 'constructor' and 'init' [args].
  /// [getControl] - Tries to find specific [ControlModel]. Looks up in current [controls], [args] and dependency Store.
  /// [Control.get] - Returns object from [ControlFactory].
  /// [Control.init] - Initializes object via [ControlFactory].
  ///
  /// Returns [controls] to init, subscribe and dispose with Widget.
  @protected
  List<ControlModel> initControls() => autoMountControls ? holder.findControls() : [];

  @override
  ControlState<ControlWidget> createState() => ControlState();

  /// Called during [State] initialization.
  /// Widget will subscribe to all [controls].
  /// Typically now need to override - check [onInit] and [onUpdate] functions.
  @protected
  @mustCallSuper
  void onInitState(ControlState state) {
    assert(isInitialized);

    if (controls == null) {
      printDebug('no controls found - onInitState');
      return;
    }

    controls.remove(null);
    controls.forEach((control) {
      control.init(holder.args);
      control.register(this);

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

    if (controls == null) {
      printDebug('no controls found - onInit');
      return;
    }

    controls.forEach((control) {
      if (control is StateControl) {
        (control as StateControl).onStateInitialized();
      }
    });
  }

  @override
  void notifyState([dynamic state]) => this.state?.notifyState(state);

  /// Callback from [State] when state is notified.
  @protected
  void onStateChanged(dynamic state) {}

  /// Returns [BuildContext] of this [Widget] or 'root' context from [ControlScope].
  BuildContext getContext({bool root: false}) => root ? Control.scope?.context ?? context : context;

  /// Tries to find specific [ControlModel]. Looks up in current [controls], [args] and dependency Store.
  /// Specific control is determined by [Type] and [key].
  /// [args] - Arguments to pass to [ControlModel].
  T getControl<T extends ControlModel>({dynamic key, dynamic args}) => Control.resolve<T>(ControlArgs(controls).combineWith(holder.argStore).data, key: key, args: args ?? holder.args);

  /// [StatelessWidget.build]
  /// [StatefulWidget.build]
  @protected
  Widget build(BuildContext context);

  /// Disposes and removes all [controls].
  /// Check [DisposeHandler] for different dispose strategies.
  @override
  @mustCallSuper
  void dispose() {
    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// [State] of [ControlWidget]
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

    widget.holder.set(controls);

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
  /// Returns currently active [Route].
  /// [Route] is typically stored in [ControlArgHolder] during navigation handling and is passed as argument.
  /// If Route is not stored in arguments, closest Route from Navigation Stack is returned.
  Route getActiveRoute() => getArg<Route>() ?? (context == null ? null : ModalRoute.of(context));

  /// Returns requested [Navigator].
  /// [root] - closest or first.
  @protected
  NavigatorState getNavigator({bool root: false}) {
    if (root && !Control.scope.isInitialized) {
      return Navigator.of(context, rootNavigator: true);
    }

    return Navigator.of(getContext(root: root)) ?? Navigator.of(context, rootNavigator: root);
  }

  @override
  void init(Map args) {
    super.init(args);

    final route = getActiveRoute();
    if (route != null) {
      printDebug('${this.toString()} at route: ${route.settings.name}');
    }
  }

  /// {@macro route-store-get}
  RouteHandler routeOf<T>([dynamic identifier]) => ControlRoute.of<T>(identifier)?.navigator(this);

  /// Initializes and returns [Route] via [RouteStore] and [RouteControl].
  ///
  /// {@macro route-store-get}
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

  @override
  void backTo({Route route, String identifier, bool Function(Route<dynamic>) predicate}) {
    if (route != null) {
      getNavigator().popUntil((item) => item == route || item.isFirst);
    }

    if (identifier != null) {
      getNavigator().popUntil((item) => item.settings.name == identifier || item.isFirst);
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
