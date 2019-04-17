import 'dart:async';

import 'package:flutter_control/core.dart';

class ActionPopupController extends BaseController {
  bool preventClose;

  ActionPopupController({this.preventClose: false});

  Future<dynamic> show(BaseController parent) => parent.openDialogController(this, root: true);

  @override
  Future<bool> navigateBack() async {
    return !preventClose;
  }
}

class InitPopupController extends ActionPopupController {
  final Getter<Widget> initializer;
  final Color color;
  final bool wrap;

  InitPopupController({@required this.initializer, this.color, this.wrap: false, bool preventClose: false}) : super(preventClose: preventClose);

  @override
  Widget initWidget() => ActionPopup(
        controller: this,
        child: initializer(),
        color: color,
        wrap: wrap,
      );
}

class ActionPopup extends BaseWidget<ActionPopupController> {
  final Color color;
  final double radius;
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool wrap;

  ActionPopup({
    Key key,
    @required ActionPopupController controller,
    this.color,
    this.radius,
    this.child,
    this.padding: const EdgeInsets.all(16.0),
    this.margin: const EdgeInsets.all(16.0),
    this.wrap: false,
  }) : super(key: key, controller: controller);

  @override
  Widget buildWidget(BuildContext context, BaseController controller) {
    return WillPopScope(
      onWillPop: controller.navigateBack,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: wrap ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: margin,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(radius ?? 24.0)),
              child: Container(
                padding: padding,
                color: color ?? Theme.of(context).backgroundColor,
                child: Material(
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
