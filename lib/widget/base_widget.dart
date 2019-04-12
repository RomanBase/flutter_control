import 'dart:async';

import 'package:flutter_control/core.dart';

/// Base StatefulWidget to cooperate with StateController.
/// Controller is then used in State.
abstract class ControlWidget<T extends StateController> extends StatefulWidget {
  /// StateController passed in constructor.
  @protected
  final T controller;

  /// Widget don't have native access to BuildContext.
  /// This one is brought thru controller, where context is passed during State initialization.
  @protected
  BuildContext get context => controller?.getContext(); // ignore: invalid_use_of_protected_member

  @protected
  Device get device => Device(MediaQuery.of(context));

  /// Default constructor
  ControlWidget({Key key, @required this.controller}) : super(key: key);

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String localize(String key) => controller?.localize(key) ?? ''; // ignore: invalid_use_of_protected_member

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String extractLocalization(Map field) => controller?.extractLocalization(field) ?? ''; // ignore: invalid_use_of_protected_member
}

/// Base State for ControlWidget and StateController
/// State is subscribed to Controller which notifies back about state changes.
abstract class ControlState<T extends StateController, U extends ControlWidget> extends State<U> implements StateNotifier {
  /// Holds controller thru widget tree changes.
  T _controller; //TODO: preserve controller settings ?

  /// StateController from parent Widget.
  T get controller => _controller;

  Device get device => widget.device;

  /// Current context from AppControl's ContextHolder
  BuildContext get rootContext => AppControl.of(context)?.currentContext ?? context;

  /// Helper function to return expected context.
  BuildContext getContext({bool root: false}) => root ? rootContext : context;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;

    _initController(controller);
  }

  /// Subscribe this State to Controller and notify Controller about initialization.
  void _initController(T controller) {
    if (controller != null) {
      if (!controller.isInitialized) {
        controller.init();
      }

      controller.subscribe(this);

      if (this is TickerProvider) {
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
    return buildWidget(context, controller);
  }

  /// Standard build function with given controller.
  Widget buildWidget(BuildContext context, T controller);

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String localize(String key) => controller?.localize(key); // ignore: invalid_use_of_protected_member

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  @protected
  String extractLocalization(Map<String, String> field) => controller?.extractLocalization(field); // ignore: invalid_use_of_protected_member

  @override
  void didUpdateWidget(U oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller = oldWidget.controller;
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
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
        return await showDialog(context: dialogContext, builder: (context) => initializer.getWidget());
      case DialogType.sheet:
        return await showModalBottomSheet(context: dialogContext, builder: (context) => initializer.getWidget());
      case DialogType.dialog:
        return await Navigator.of(dialogContext).push(MaterialPageRoute(builder: (BuildContext context) => initializer.getWidget(), fullscreenDialog: true));
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
  final bool ticker;

  /// Default constructor
  BaseWidget({Key key, @required T controller, this.ticker: false}) : super(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => ticker ? _BaseWidgetTickerState() : _BaseWidgetState();

  /// Standard build function with given controller exposed directly to Widget.
  @protected
  Widget buildWidget(BuildContext context, T controller);
}

/// Shortcut State for BaseWidget. It just expose build function to Widget.
class _BaseWidgetState<T extends StateController> extends BaseState<T, BaseWidget> {
  @override
  Widget buildWidget(BuildContext context, T controller) {
    return widget.buildWidget(context, controller);
  }
}

/// Shortcut State for BaseWidget. It just expose build function to Widget.
/// This State is initialized with TickerProviderMixin.
class _BaseWidgetTickerState<T extends StateController> extends BaseState<T, BaseWidget> with TickerProviderStateMixin {
  @override
  Widget buildWidget(BuildContext context, T controller) {
    return widget.buildWidget(context, controller);
  }
}
