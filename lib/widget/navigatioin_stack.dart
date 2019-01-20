import 'package:flutter_control/core.dart';

/// Controller with its own Navigator.
/// Routes pushed by this controller are pushed into custom navigation stack.
class NavigationController extends BaseController {
  /// Name of the controller - typically used for menu items.
  final String title;

  /// Icon name/path of the controller - typically used for menu items.
  final String icon;

  /// Initial Controller, that will be pushed into navigation as first Widget.
  final Action<StateController> initializer;

  /// Arguments for controller initialization.
  final List args;

  /// Typically used for menu items.
  bool isSelected = false;

  /// Initial controller.
  StateController _controller;

  /// Checks if initial Controller is available.
  bool get isRootInitialized => _controller != null;

  /// Default constructor.
  NavigationController(this.title, this.icon, this.initializer, [this.args]);

  /// returns initial controller.
  /// If controller isn't initialized yet, then initialization is called.
  StateController getRootController() {
    if (_controller == null) {
      _controller = initializer();
      _controller.parent = this;
      _controller.init(args);
    }

    return _controller;
  }

  /// Tries to navigate back in custom navigation stack.
  /// returns true if Widget was popped from stack.
  bool navigateBack() {
    if (!isRootInitialized) {
      return false;
    }

    final navigator = Navigator.of(getRootController().getContext());

    if (navigator.canPop()) {
      navigator.pop();
      return true;
    }

    return false;
  }

  /// Pops all Widgets from navigation stack until root controller.
  @override
  void reload() {
    if (!isRootInitialized) {
      return;
    }

    final navigator = Navigator.of(getRootController().getContext());

    while (navigator.canPop()) {
      if (!navigator.pop()) {
        break;
      }
    }
  }

  @override
  Widget initWidget() => NavigationStack(this);
}

/// Init Widget with custom GlobalKey.
/// Controller is used as GlobalObjectKey to prevent Widget caching in multiple NavigationStack solution.
class NavigationStack extends ControlWidget<NavigationController> {
  /// Default constructor
  NavigationStack(NavigationController controller) : super(controller: controller, key: GlobalObjectKey(controller));

  @override
  State<StatefulWidget> createState() => _NavigationStackState();
}

/// Creates new Navigator with given controller as first Widget in stack.
class _NavigationStackState extends BaseState<NavigationController, NavigationStack> {
  @override
  Widget buildWidget(BuildContext context, NavigationController controller) {
    return Navigator(
      onGenerateRoute: (routeSettings) {
        final root = controller.getRootController();

        if (root is BaseController) {
          return root.getRoute(settings: routeSettings);
        }

        return MaterialPageRoute(builder: (context) => controller.getRootController().getWidget());
      },
    );
  }
}
