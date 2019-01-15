import 'package:flutter_control/core.dart';

class NavigationController extends BaseController {
  final String title;
  final String icon;
  final Action<StateController> initializer;
  final List<dynamic> args;

  bool isSelected = false;

  StateController _controller;

  bool get isRootInitialized => _controller != null;

  NavigationController(this.title, this.icon, this.initializer, [this.args]);

  StateController getRootController() {
    if (_controller == null) {
      _controller = initializer();
      _controller.init(args);
    }

    return _controller;
  }

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

class NavigationStack extends ControlWidget<NavigationController> {
  NavigationStack(NavigationController controller) : super(controller: controller, key: GlobalObjectKey(controller));

  @override
  State<StatefulWidget> createState() => _NavigationStackState();
}

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
