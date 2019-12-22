import 'dart:async';

import 'package:flutter_control/core.dart';

class WidgetControlHolder implements Disposable {
  Map args;
  ControlState state;
  Route route;

  bool get initialized => state != null;

  void addArg(dynamic args) {
    if (args == null) {
      return;
    }

    if (this.args == null) {
      this.args = Map();
    }

    if (args is Map) {
      args.forEach((key, value) {
        this.args[key] = value;
      });
    } else if (args is Iterable) {
      args.forEach((item) {
        this.args[item.runtimeType] = item;
      });
    } else {
      this.args[args.runtimeType] = args;
    }
  }

  T getArg<T>({String key, T defaultValue}) => Parse.getArgFromMap<T>(args, key: key, defaultValue: defaultValue);

  bool findRoute([BuildContext context]) {
    if (route != null) {
      return true;
    }

    route = Parse.getArg<Route>(args, key: ControlKey.initData);

    if (route == null && context != null) {
      ModalRoute.of(context);
    }

    return route != null;
  }

  List<BaseControlModel> findControls() {
    if (args == null) {
      return [];
    }

    return args.values.where((item) => item is BaseControlModel).toList(growable: false).cast<BaseControlModel>();
  }

  @override
  void dispose() {
    state = null;
    args = null;
  }
}

/// [ControlWidget] with just one init Controller.
abstract class SingleControlWidget<T extends BaseControlModel> extends ControlWidget {
  T get controller => controllers[0];

  SingleControlWidget({Key key, dynamic args}) : super(key: key, args: args);

  @override
  List<BaseControlModel> initControllers() {
    return [initController()];
  }

  @protected
  T initController() {
    T item = holder.getArg<T>();

    if (item == null) {
      item = ControlProvider.get<T>(null, holder.args);
    }

    return item;
  }
}

/// [ControlWidget] with no init Controllers.
abstract class BaseControlWidget extends ControlWidget {
  BaseControlWidget({Key key, dynamic args}) : super(key: key, args: args);

  @override
  List<BaseControlModel> initControllers() => null;
}

/// Base [StatefulWidget] to cooperate with [BaseController].
/// [BaseController]
/// [StateController]
///
/// [RouteControl] & [RouteController]
/// [RouteHandler] & [PageRouteProvider]
///
/// [ControlFactory]
/// [AppControl]
/// [BaseLocalization]
///
/// [ControlState]
/// [_ControlTickerState]
/// [_ControlSingleTickerState]
abstract class ControlWidget extends StatefulWidget with LocalizationProvider implements Initializable, Disposable {
  /// Holder for [State] nad Controllers.
  @protected
  final holder = WidgetControlHolder();

  bool get isInitialized => holder.initialized;

  /// Widget's [State]
  /// [holder] - [onInitState]
  @protected
  ControlState get state => holder.state;

  /// List of Controllers passed during construction phase.
  /// [holder] - [initControllers]
  List<BaseControlModel> get controllers => holder.state?.controllers;

  /// Context of Widget's [State]
  BuildContext get context => state?.context;

  /// Instance of [ControlFactory].
  @protected
  ControlFactory get factory => ControlFactory.of(this);

  /// Instance of [AppControl].
  @protected
  AppControl get control => AppControl.of(context);

  /// Default constructor
  ControlWidget({Key key, dynamic args}) : super(key: key) {
    addArg(args);
  }

  /// Called during construction phase.
  /// Returned controllers will be notified during Widget/State initialization.
  @protected
  List<BaseControlModel> initControllers();

  @override
  ControlState<ControlWidget> createState() => ControlState();

  /// When [RouteHandler] is used, then this function is called right after Widget construction. +
  /// All controllers (from [initControllers]) are initialized too.
  @override
  @protected
  @mustCallSuper
  void init(Map args) => addArg(args);

  /// Called during State initialization.
  /// All controllers (from [initControllers]) are subscribed to this Widget and given State.
  @protected
  @mustCallSuper
  void onInitState(ControlState state) {
    notifyWidget(state);

    controllers?.remove(null);
    controllers?.forEach((controller) {
      controller.init(holder.args);
      controller.subscribe(this);

      if (state is TickerProvider) {
        (controller as BaseController).onTickerInitialized(state as TickerProvider);
      }

      if (controller is StateController) {
        controller.subscribe(state);
        state._createSub(controller);
        controller.onStateInitialized();
      }
    });
  }

  /// Called by State whenever [holder] isn't initialized or when something has dramatically changed in Widget - State relationship.
  @protected
  void notifyWidget(ControlState state) {
    assert(() {
      if (holder.initialized) {
        printDebug('something is maybe wrong, state reinitialized...');
        printDebug('old state: ${this.state}');
        printDebug('new state: $state');
      }
      return true;
    }());

    if (this.state == state) {
      return;
    }

    holder.state = state;
  }

  /// Notifies [State] of this [Widget].
  void notifyState(dynamic state) => holder.state?.notifyState(state);

  /// Callback from [State] when state is notified.
  @protected
  void onStateChanged(dynamic state) {}

  /// Returns context of this widget or [root] context that is stored in [AppControl]
  BuildContext getContext({bool root: false}) => root ? control.rootContext ?? context : context;

  /// Returns value by given key or type.
  /// Args are passed to Widget in constructor and during [init] phase or can be added via [ControlWidget.addArg].
  T getArg<T>({String key, T defaultValue}) => holder.getArg(key: key, defaultValue: defaultValue);

  /// Returns value by given key or type.
  /// Look up in [controllers] and [factory].
  /// Use [getArg] to look up in Widget's arguments.
  T getControl<T>({String key, dynamic args}) => factory.find(controllers, includeFactory: true, args: args);

  /// Adds [arg] to this widget.
  /// [args] can be whatever - [Map], [List], [Object], or any primitive.
  /// [args] are then parsed into [Map].
  void addArg(dynamic args) => holder.addArg(args);

  /// [StatelessWidget.build]
  /// [StatefulWidget.build]
  @protected
  Widget build(BuildContext context);

  /// Disposes and removes all [controllers].
  /// Controller can prevent disposing [BaseController.preventDispose].
  @override
  @mustCallSuper
  void dispose() {
    printDebug('dispose ${this.toString()}');
  }
}

/// Base State for ControlWidget and StateController
/// State is subscribed to Controller which notifies back about state changes.
class ControlState<U extends ControlWidget> extends State<U> implements StateNotifier {
  /// List of Subscriptions from [StateController]s
  List<ControlSubscription> _stateSubs;

  List<BaseControlModel> controllers;

  @override
  void initState() {
    super.initState();

    if (widget is ThemeProvider) {
      (widget as ThemeProvider).invalidateTheme(context);
    }

    controllers = widget.initControllers();

    if (controllers == null) {
      controllers = <BaseControlModel>[];
    }

    final argControls = widget.holder.findControls();

    argControls.forEach((item) {
      if (!controllers.contains(item)) {
        controllers.add(item);
      }
    });

    widget.onInitState(this);
  }

  @override
  void notifyState([dynamic state]) {
    setState(() {
      widget.onStateChanged(state);
    });
  }

  @protected
  void notifyWidget() {
    if (widget is ThemeProvider) {
      (widget as ThemeProvider).invalidateTheme(context);
    }

    if (!widget.holder.initialized) {
      widget.notifyWidget(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    notifyWidget();

    return widget.build(context);
  }

  void _createSub(StateController controller) {
    if (_stateSubs == null) {
      _stateSubs = List<ControlSubscription>();
    }

    _stateSubs.add(controller.subscribeStateNotifier(notifyState));
  }

  /// Disposes and removes all [controllers].
  /// Controller can prevent disposing [BaseController.preventDispose].
  /// Then disposes Widget.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();

    if (_stateSubs != null) {
      _stateSubs.forEach((sub) => sub.cancel());
      _stateSubs.clear();
      _stateSubs = null;
    }

    if (controllers != null) {
      controllers.forEach((controller) => controller.requestDispose());
      controllers.clear();
      controllers = null;
    }

    widget.holder.dispose();
    widget.dispose();
  }
}

/// [ControlState] with [TickerProviderStateMixin]
class _ControlTickerState<U extends ControlWidget> extends ControlState<U> with TickerProviderStateMixin {}

/// [ControlState] with [SingleTickerProviderStateMixin]
class _ControlSingleTickerState<U extends ControlWidget> extends ControlState<U> with SingleTickerProviderStateMixin {}

/// Helps [ControlWidget] to create State with [TickerProviderStateMixin]
/// Use [SingleTickerControl] to create State with [SingleTickerProviderStateMixin].
mixin TickerControl on ControlWidget {
  @protected
  TickerProvider get ticker => holder.state as TickerProvider;

  @override
  ControlState<ControlWidget> createState() => _ControlTickerState();
}

/// Helps [ControlWidget] to create State with [SingleTickerProviderStateMixin]
/// Use [TickerControl] to create State with [TickerProviderStateMixin].
mixin SingleTickerControl on ControlWidget {
  @protected
  TickerProvider get ticker => holder.state as TickerProvider;

  @override
  ControlState<ControlWidget> createState() => _ControlSingleTickerState();
}

/// Mixin class to enable navigation for [ControlWidget]
mixin RouteControl on ControlWidget implements RouteNavigator {
  NavigatorState get navigator => Navigator.of(context);

  NavigatorState get rootNavigator => Navigator.of(getContext(root: true));

  @override
  void init(Map args) {
    super.init(args);

    if (holder.findRoute(context)) {
      printDebug('${this.toString()} at route: ${holder.route.settings.name}');
    }
  }

  @override
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false}) {
    if (replacement) {
      return navigator.pushReplacement(route);
    } else {
      return (root ? rootNavigator : navigator).push(route);
    }
  }

  @override
  Future<dynamic> openRoot(Route route) {
    return navigator.pushAndRemoveUntil(route, (pop) => false);
  }

  @override
  Future<dynamic> openDialog(WidgetBuilder builder, {bool root: false, DialogType type: DialogType.popup}) async {
    final dialogContext = getContext(root: root);

    //TODO: dialogs
    switch (type) {
      case DialogType.popup:
        return await showDialog(context: dialogContext, builder: (context) => builder(context));
      case DialogType.sheet:
        return await showModalBottomSheet(context: dialogContext, builder: (context) => builder(context));
      case DialogType.dialog:
        return await Navigator.of(dialogContext).push(MaterialPageRoute(builder: (BuildContext context) => builder(context), fullscreenDialog: true));
      case DialogType.dock:
        return showBottomSheet(context: dialogContext, builder: (context) => builder(context));
    }

    return null;
  }

  void backTo({Route route, String identifier, bool Function(Route<dynamic>) predicate}) {
    if (route != null) {
      navigator.popUntil((item) => item == route);
    }

    if (identifier != null) {
      navigator.popUntil((item) => item.settings.name == identifier);
    }

    if (predicate != null) {
      navigator.popUntil(predicate);
    }
  }

  @override
  void backToRoot() {
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  void close([dynamic result]) {
    if (holder.route != null) {
      closeRoute(holder.route, result);
    } else {
      navigator.pop(result);
    }
  }

  @override
  void closeRoute(Route route, [dynamic result]) {
    if (route.isCurrent) {
      navigator.pop(result);
    } else {
      // ignore: invalid_use_of_protected_member
      route.didComplete(result);
      navigator.removeRoute(route);
    }
  }
}
