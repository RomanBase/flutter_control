import 'package:flutter_control/core.dart';

//TODO: expose more settings of Scaffold
/// Shortcut Widget for ControlWidget.
/// State with Scaffold is created automatically and build functions are exposed directly to Widget.
/// Because Controller holds everything important and notifies about state changes, there is no need to build complex State.
abstract class BasePage<T extends BaseController> extends ControlWidget<T> {
  final bool ticker;
  final bool primary;
  final bool resizeToAvoidBottomPadding;
  final bool popScope;

  /// Default constructor
  BasePage({Key key, @required T controller, this.ticker: false, this.primary: true, this.popScope: false, this.resizeToAvoidBottomPadding: false}) : super(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => ticker ? _BasePageTickerState() : _BasePageState();

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

  /// Build root Widget.
  @protected
  Widget buildScaffold(BuildContext context, T controller) {
    final scaffold = Scaffold(
      primary: primary,
      resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: buildAppBar(context, controller),
      body: buildPage(context, controller),
      bottomNavigationBar: buildBottomNavigation(context, controller),
      bottomSheet: buildBottomSheet(context, controller),
      drawer: buildDrawer(context, controller),
    );

    if (popScope) {
      return WillPopScope(
        onWillPop: controller.navigateBack,
        child: scaffold,
      );
    } else {
      return scaffold;
    }
  }
}

/// Shortcut State for BasePage. It just expose build functions to Widget.
/// PopScope and Scaffold is created in default build.
/// Basic Scaffold settings is populated to Widget part.
class _BasePageState<T extends BaseController> extends BaseState<T, BasePage> {
  @override
  Widget buildWidget(BuildContext context, T controller) {
    return widget.buildScaffold(context, controller);
  }
}

/// Shortcut State for BasePage. It just expose build functions to Widget.
/// PopScope and Scaffold is created in default build.
/// Basic Scaffold settings is populated to Widget part.
/// This State is initialized with TickerProviderMixin.
class _BasePageTickerState<T extends BaseController> extends BaseState<T, BasePage> with TickerProviderStateMixin {
  @override
  Widget buildWidget(BuildContext context, T controller) {
    return widget.buildScaffold(context, controller);
  }
}
