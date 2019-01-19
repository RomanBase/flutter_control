import 'package:flutter_control/core.dart';

enum DialogType { popup, sheet, dock }

typedef Action<T> = T Function();

abstract class Initializable {
  void onInit(List args) {}
}

abstract class Disposable {
  void dispose();
}

abstract class StateNotifier {
  void notifyState({dynamic state});
}

abstract class RouteNavigator {
  Future<dynamic> openRoute(Route route, {bool root: false});

  Future<dynamic> openRoot(Route route);

  Future<dynamic> openDialog(WidgetInitializer initializer, {bool root: false, DialogType type: DialogType.popup});

  void backTo(String route);

  void close({dynamic result});
}

abstract class RouteIdentifier {
  String get routeIdentifier;

  @protected
  Route getRoute({RouteSettings settings});
}

abstract class WidgetInitializer {
  Widget _widget;

  @protected
  Widget initWidget();

  Widget getWidget() => _widget ?? (_widget = initWidget());
}

abstract class StateController implements Initializable, Disposable, StateNotifier, WidgetInitializer {
  @override
  Widget _widget;

  BuildContext _context;

  StateNotifier _stateNotifier;

  dynamic parent;

  bool get isWidgetInitialized => _widget != null;

  Widget init([List args]) {
    onInit(args);

    return getWidget();
  }

  @override
  void onInit(List args) {}

  @override
  void notifyState({dynamic state}) {
    _stateNotifier?.notifyState(state: state);
  }

  @protected
  void onStateInitialized(State state) {}

  @protected
  void onTickerInitialized(TickerProvider ticker) {}

  void reload() {}

  void subscribe(dynamic object) {
    if (_widget == null) {
      if (object is Widget) {
        _widget = object;
      } else if (object is State) {
        _widget = object.widget;
      }
    }

    if (object is State) {
      _context = object.context;
    }

    if (object is StateNotifier) {
      _stateNotifier = object;
    }
  }

  @protected
  BuildContext getContext() => _context;

  @override
  Widget getWidget() => _widget ?? (_widget = initWidget());

  @protected
  String localize(String key) => AppControl.of(_context)?.localize(key);

  @protected
  String extractLocalization(Map<String, String> field) => AppControl.of(_context)?.extractLocalization(field);

  @override
  void dispose() {
    _stateNotifier = null;
    _widget = null;
    parent = null;
  }
}

abstract class BaseController extends StateController implements RouteNavigator, RouteIdentifier {
  @override
  String get routeIdentifier => this.toString();

  RouteNavigator _navigator;

  final isLoading = FieldController<bool>(false);

  Future<bool> onBackPressed() async => true;

  void subscribeNavigator(RouteNavigator navigator) {
    _navigator = navigator;
  }

  @override
  void subscribe(dynamic object) {
    super.subscribe(object);

    if (object is RouteNavigator) {
      subscribeNavigator(object);
    }
  }

  @override
  Future<dynamic> openRoute(Route route, {bool root: false}) {
    return _navigator?.openRoute(route, root: root);
  }

  @override
  Future<dynamic> openRoot(Route route) {
    return _navigator?.openRoot(route);
  }

  @override
  Future<dynamic> openDialog(WidgetInitializer widget, {bool root: false, DialogType type: DialogType.popup}) {
    return _navigator?.openDialog(widget, root: root, type: type);
  }

  @override
  void backTo(String route) {
    _navigator?.backTo(route);
  }

  @override
  void close({dynamic result}) {
    _navigator?.close(result: result);
  }

  @override
  void dispose() {
    super.dispose();
    isLoading.dispose();
    _navigator = null;
  }

  Future<dynamic> openController(BaseController controller, {bool root: false, List args}) {
    controller.parent = this;
    controller.onInit(args);
    return openRoute(controller.getRoute(), root: root);
  }

  Future<dynamic> openRootController(BaseController controller, {List args}) {
    controller.onInit(args);
    return openRoot(controller.getRoute());
  }

  Future<dynamic> openDialogController(StateController controller, {bool root: false, List args}) {
    controller.onInit(args);
    return openDialog(controller, root: root);
  }

  @override
  Route getRoute({RouteSettings settings}) {
    //TODO: more settings
    final routeSettings = settings ?? RouteSettings(name: routeIdentifier ?? this.toString());

    return MaterialPageRoute(builder: (context) => getWidget());
  }
}
