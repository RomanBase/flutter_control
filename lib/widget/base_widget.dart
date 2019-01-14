import 'package:flutter_control/core.dart';

abstract class ControlWidget<T extends StateController> extends StatefulWidget {
  @protected
  final T controller;

  ControlWidget({Key key, @required this.controller}) : super(key: key);
}

abstract class ControlState<T extends StateController, U extends ControlWidget> extends State<U> implements StateNotifier {
  T get controller => widget.controller;

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
  Future<dynamic> openDialog(WidgetInitializer initializer, {DialogType type: DialogType.popup}) {
    switch (type) {
      case DialogType.popup:
        return showDialog(context: context, builder: (context) => initializer.getWidget());
      case DialogType.sheet:
        return showModalBottomSheet(context: context, builder: (context) => initializer.getWidget());
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

  Widget buildPage(BuildContext context, T controller);
}

class _BaseWidgetState<T extends BaseController> extends BaseState<T, BasePage> {
  @override
  Widget buildWidget(BuildContext context, StateController controller) {
    return widget.buildPage(context, controller); // ignore: invalid_use_of_protected_member
  }
}
