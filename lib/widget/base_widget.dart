import 'package:flutter_control/core.dart';

/// Base StatefulWidget to cooperate with StateController.
/// Controller is then used in State.
abstract class ControlWidget<T extends StateController> extends StatefulWidget {
  /// StateController passed in constructor.
  /// Controller is initialized and used in State.
  @protected
  final T controller;

  /// Widget don't have native access to BuildContext.
  /// This one is brought thru controller, where context is passed during State initialization.
  @protected
  BuildContext get context => controller.getContext(); // ignore: invalid_use_of_protected_member

  /// Default constructor
  ControlWidget({Key key, @required this.controller}) : super(key: key);

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String localize(String key) => AppControl.of(context)?.localize(key);

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String extractLocalization(Map<String, String> field) => AppControl.of(context)?.extractLocalization(field);
}

/// Base State for ControlWidget and StateController
/// State is subscribed to Controller which notifies back about state changes.
abstract class ControlState<T extends StateController, U extends ControlWidget> extends State<U> implements StateNotifier {
  /// StateController from parent Widget.
  T get controller => widget.controller;

  /// Root context of App.
  /// Mainly used for Navigator.
  /// Context is part of AppControl.
  /// If AppControl isn't found, standard context is returned.
  BuildContext get rootContext => AppControl.of(context)?.context ?? context;

  /// Helper function to return expected context.
  BuildContext getContext({bool root: false}) => root ? rootContext : context;

  @override
  void initState() {
    super.initState();

    _initController(widget.controller);
  }

  /// Subscribe this state to Controller and notify Controller about initialization.
  void _initController(T controller) {
    if (controller != null) {
      controller.subscribe(this);

      // TODO: test
      if (this.runtimeType is TickerProvider) {
        controller.onTickerInitialized(this as TickerProvider); // ignore: invalid_use_of_protected_member
      }

      controller.onStateInitialized(this); // ignore: invalid_use_of_protected_member
    }
  }

  @override
  void notifyState({state}) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return buildWidget(context, widget.controller);
  }

  /// Standard build function with given controller.
  Widget buildWidget(BuildContext context, T controller);

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String localize(String key) => AppControl.of(context)?.localize(key);

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String extractLocalization(Map<String, String> field) => AppControl.of(context)?.extractLocalization(field);

  @override
  void dispose() {
    super.dispose();
    widget.controller?.dispose();
  }
}

/// Base State for ControlWidget and BaseController
/// State is subscribed to Controller which notifies back about state changes.
/// Adds navigation possibility to default ControlState
abstract class BaseState<T extends StateController, U extends ControlWidget> extends ControlState<T, U> implements RouteNavigator {
  @override
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false}) {
    if (replacement) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(getContext(root: root)).push(route);
    }
  }

  @override
  Future<dynamic> openRoot(Route route) {
    return Navigator.of(context).pushAndRemoveUntil(route, (Route<dynamic> pop) => false);
  }

  @override
  Future<dynamic> openDialog(WidgetInitializer initializer, {bool root: false, DialogType type: DialogType.popup}) async {
    final dialogContext = getContext(root: root);

    switch (type) {
      case DialogType.popup:
        return showDialog(context: dialogContext, builder: (context) => initializer.getWidget());
      case DialogType.sheet:
        return showModalBottomSheet(context: dialogContext, builder: (context) => initializer.getWidget());
      case DialogType.dock:
        return showBottomSheet(context: dialogContext, builder: (context) => initializer.getWidget());
    }

    return null;
  }

  @override
  void backTo(String route) {
    Navigator.of(context).popUntil((Route<dynamic> pop) => pop.settings.name == route);
  }

  @override
  void close({dynamic result}) {
    Navigator.of(context).pop(result);
  }
}

/// Shortcut Widget for ControlWidget.
/// State is created automatically and build function is exposed directly to Widget.
/// Because Controller holds everything important and notifies about state changes, there is no need to build complex State.
abstract class BaseWidget<T extends StateController> extends ControlWidget<T> {
  /// Default constructor
  BaseWidget({Key key, @required T controller}) : super(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => _BaseWidgetState();

  /// Standard build function with given controller exposed directly to Widget.
  Widget buildWidget(BuildContext context, T controller);
}

/// Shortcut State for BaseWidget. It just expose build function to Widget.
class _BaseWidgetState<T extends StateController> extends BaseState<T, BaseWidget> {
  @override
  Widget buildWidget(BuildContext context, T controller) {
    return widget.buildWidget(context, controller); // ignore: invalid_use_of_protected_member
  }
}
