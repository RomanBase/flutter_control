import 'package:flutter_control/core.dart';

abstract class ControlWidget<T extends StateController> extends StatefulWidget {
  @protected
  final T controller;

  @protected
  BuildContext get context => controller.getContext();

  ControlWidget({Key key, @required this.controller}) : super(key: key);

  @protected
  String localize(String key) => AppControl.of(context)?.localize(key);

  @protected
  String extractLocalization(Map<String, String> field) => AppControl.of(context)?.extractLocalization(field);
}

abstract class ControlState<T extends StateController, U extends ControlWidget> extends State<U> implements StateNotifier {
  T get controller => widget.controller;

  BuildContext get rootContext => AppControl.of(context)?.context;

  @override
  void initState() {
    super.initState();

    _initController(widget.controller);
  }

  void _initController(T controller) {
    if (controller != null) {
      controller.subscribe(this);

      // TODO: test
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
    return buildWidget(context, widget.controller);
  }

  Widget buildWidget(BuildContext context, T controller);

  @protected
  String localize(String key) => AppControl.of(context)?.localize(key);

  @protected
  String extractLocalization(Map<String, String> field) => AppControl.of(context)?.extractLocalization(field);

  @override
  void dispose() {
    super.dispose();
    widget.controller?.dispose();
  }
}

abstract class BaseState<T extends StateController, U extends ControlWidget> extends ControlState<T, U> implements RouteNavigator {
  @override
  Future<dynamic> openRoute(Route route, {bool root: false}) {
    if (root) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }

  @override
  Future<dynamic> openRoot(Route route) {
    return Navigator.of(context).pushAndRemoveUntil(route, (Route<dynamic> pop) => false);
  }

  @override
  Future<dynamic> openDialog(WidgetInitializer initializer, {bool root: false, DialogType type: DialogType.popup}) async {
    final control = AppControl.of(context);
    final dialogContext = root ? (control?.context ?? context) : context;

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

abstract class BaseWidget<T extends BaseController> extends ControlWidget<T> {
  BaseWidget({
    Key key,
    @required T controller,
  }) : super(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => _BaseWidgetState();

  Widget buildWidget(BuildContext context, T controller);
}

class _BaseWidgetState<T extends BaseController> extends BaseState<T, BaseWidget> {
  @override
  Widget buildWidget(BuildContext context, StateController controller) {
    return widget.buildWidget(context, controller); // ignore: invalid_use_of_protected_member
  }
}
