import 'package:flutter_control/core.dart';

abstract class BasePage<T extends BaseController> extends ControlWidget<T> {
  BasePage({
    Key key,
    @required T controller,
  }) : super(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => _BasePageState();

  @protected
  Widget buildPage(BuildContext context, T controller);

  @protected
  AppBar buildAppBar(BuildContext context, T controller) {
    return null;
  }

  @protected
  Widget buildBottomNavigation(BuildContext context, T controller) {
    return null;
  }

  @protected
  Widget buildBottomSheet(BuildContext context, T controller) {
    return null;
  }

  @protected
  Widget buildDrawer(BuildContext context, T controller) {
    return null;
  }

  BuildContext get context => controller.getContext(); // ignore: invalid_use_of_protected_member
}

class _BasePageState<T extends BaseController> extends BaseState<T, BasePage> {
  @override
  Widget buildWidget(BuildContext context, T controller) {
    return WillPopScope(
      onWillPop: controller.onBackPressed,
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: widget.buildAppBar(context, controller),
        body: widget.buildPage(context, controller),
        bottomNavigationBar: widget.buildBottomNavigation(context, controller),
        bottomSheet: widget.buildBottomSheet(context, controller),
        drawer: widget.buildDrawer(context, controller),
      ),
    );
  }
}
