import 'package:flutter_control/core.dart';

//TODO: expose more settings of Scaffold
/// Shortcut Widget for ControlWidget.
/// State with Scaffold is created automatically and build functions are exposed directly to Widget.
/// Because Controller holds everything important and notifies about state changes, there is no need to build complex State.
abstract class BasePage<T extends BaseController> extends ControlWidget<T> {
  /// Default constructor
  BasePage({Key key, @required T controller}) : super(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => _BasePageState();

  /// Build body for Scaffold.
  @protected
  Widget buildPage(BuildContext context, T controller);

  /// Build AppBar for Scaffold.
  @protected
  AppBar buildAppBar(BuildContext context, T controller) {
    return null;
  }

  /// Build BottomNavigation for Scaffold.
  @protected
  Widget buildBottomNavigation(BuildContext context, T controller) {
    return null;
  }

  /// Build BottomSheet for Scaffold.
  @protected
  Widget buildBottomSheet(BuildContext context, T controller) {
    return null;
  }

  /// Build Drawer for Scaffold.
  @protected
  Widget buildDrawer(BuildContext context, T controller) {
    return null;
  }
}

/// Shortcut State for BasePage. It just expose build functions to Widget.
/// PopScope and Scaffold is created in default build.
/// Basic Scaffold settings is populated to Widget part.
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
