import 'package:flutter_control/core.dart';

/// Types of dialogs for RouteNavigator.
enum DialogType { popup, sheet, dock }

enum LoadingStatus { none, progress, done, error, outdated, unknown }

typedef Getter<T> = T Function();
typedef Action<T> = Function(T);
typedef Converter<T> = T Function(dynamic);
typedef Notifier<T> = Function(T);

/// Standard initialization of object right after constructor;
abstract class Initializable {
  /// Is typically called right after constructor.
  void onInit(List args) {} //TODO: Maybe rework to Map ???
}

/// Standard disposable implementation.
abstract class Disposable {
  /// Used to clear and dispose object.
  /// After this method call is object typically unusable and ready for GC.
  /// Can be called multiple times!
  void dispose();
}

/// Base abstract class for communication between Controller and different types of State.
/// State will be set by Controller.
/// This class needs to be implemented in State.
abstract class StateNotifier {
  /// Notifies about state changes and requests State to rebuild UI.
  void notifyState({dynamic state});
}

/// Route navigation for Navigator.
/// Navigation will be handled by Controller.
/// This class needs to be implemented in State.
abstract class RouteNavigator {
  /// Pushes route into current Navigator.
  /// root - pushes route into root Navigator - onto top of everything.
  /// replacement - pushes route as replacement of current route.
  ///
  /// Scaffold as root context for Navigator is part of BaseApp Widget.
  /// As well AppControl can be initialized with custom root context and root Key.
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false});

  /// Clears current Navigator and opens new Route.
  Future<dynamic> openRoot(Route route);

  /// Opens Dialog/ModalSheet/BottomSheet etc. as custom Widget Dialog via Controller.
  ///
  /// Scaffold as root context for Navigator is part of BaseApp Widget.
  /// As well AppControl can be initialized with custom root context and root Key.
  Future<dynamic> openDialog(WidgetInitializer initializer, {bool root: false, DialogType type: DialogType.popup});

  /// Goes back in navigation stack until Route with given name is found.
  void backTo(String route);

  /// Pop route from navigation stack.
  /// result is send back to parent.
  void close({dynamic result});
}

/// Route initializer for Navigator.
/// Identifier is passed as route name.
/// With identifier is possible to restore app state or go back many steps in navigation.
abstract class RouteIdentifier {
  /// Name of the route in navigation path.
  /// With identifier is possible to restore app state or go back many steps in navigation.
  String get routeIdentifier;

  /// initialize Route for Navigator.
  /// settings is typically null.
  @protected
  Route getRoute({RouteSettings settings});
}

/// Simple widget initializer and holder.
/// initWidget is typically called from parent class or as initializer.
/// initWidget can return NULL, when controller is too general and is set directly to Widget in build phase.
abstract class WidgetInitializer {
  /// Current Widget.
  Widget _widget;

  /// This function is typically called by framework.
  @protected
  Widget initWidget();

  /// returns current Widget or tries to initialize new one.
  Widget getWidget() => _widget ?? (_widget = initWidget());
}

/// Initializes Widget and controls State.
/// initWidget is typically called from parent class or as initializer.
/// initWidget can return NULL, when controller is too general and is set directly to widget in build phase.
class StateController implements Initializable, Disposable, StateNotifier, WidgetInitializer {
  /// Widget can be initialized in two ways:
  /// - initWidget
  /// - subscribe
  @override
  Widget _widget;

  /// BuildContext of current State.
  BuildContext _context;

  /// State which inherits from StateNotifier.
  StateNotifier _stateNotifier;

  /// init check.
  bool _isInitialized = false;

  /// return true if init function was called before.
  bool get isInitialized => _isInitialized;

  /// Parent Controller - close result will be delivery to parent.
  /// Parent context is used when Widget is not initialized yet.
  StateController parent;

  /// return true if Widget is not null.
  bool get isWidgetInitialized => _widget != null;

  /// return true if BuildContext is not null.
  bool get isContextInitialized => getContext() != null;

  /// returns AppControl if available.
  /// nullable
  AppControl get control => AppControl.of(getContext());

  /// returns AppFactory if available.
  /// nullable
  AppFactory get factory => AppControl.factory(this);

  /// Is typically called by framework in openController functions.
  /// Can be used to re-init Controller.
  @mustCallSuper
  StateController init([List args]) {
    _isInitialized = true;
    onInit(args);

    return this;
  }

  /// Is typically called right after constructor.
  /// Widget or State isn't available yet.
  @override
  void onInit(List args) {}

  /// returns Object from List with given Type.
  /// defaultValue is used if Type is not found in List.
  T getArg<T>(List args, Type type, {T defaultValue}) {
    for (var item in args) {
      if (type == item.runtimeType) {
        return item;
      }
    }

    return defaultValue;
  }

  @override
  void notifyState({dynamic state}) {
    _stateNotifier?.notifyState(state: state);
  }

  /// Call this function from State during initState phase.
  @protected
  void onStateInitialized(State state) {}

  /// Call this function from State during initState phase when State inherits from TickerProvider.
  /// Here is time to initialize all Animation Controllers.
  @protected
  void onTickerInitialized(TickerProvider ticker) {}

  /// Used to reload Controller.
  /// Currently empty and is ready to override.
  void reload() {}

  /// Call this function from State during initState phase.
  /// From now can be State controlled by this Controller.
  /// State must implement StateNotifier for proper functionality.
  /// This function can be override for more complex subscription.
  @mustCallSuper
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

  /// returns context of controlled State if exist.
  /// nullable
  @protected
  BuildContext getContext() => _context ?? parent?._context;

  /// This function is typically called by framework.
  /// nullable
  @protected
  Widget initWidget() => null;

  /// returns current widget or tries to initialize new one.
  /// nullable
  @override
  Widget getWidget({bool forceInit: false}) => forceInit ? _widget = initWidget() : _widget ?? (_widget = initWidget());

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  /// Non null.
  @protected
  String localize(String key) => AppControl.localization(this)?.localize(key) ?? '';

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  /// Non null.
  @protected
  String extractLocalization(Map field) => AppControl.localization(this)?.extractLocalization(field) ?? '';

  /// Typically is this method called during State disable phase.
  /// Disables linking between Controller and State.
  @override
  @mustCallSuper
  void dispose() {
    _stateNotifier = null;
    _widget = null;
    parent = null;
  }
}

/// Initializes Widget and controls State.
/// initWidget is typically called from parent class or as initializer.
/// initWidget can return NULL, when controller is too general and is set directly to widget in build phase.
/// Adds navigation to StateController.
class BaseController extends StateController implements RouteNavigator, RouteIdentifier {
  @override
  String get routeIdentifier => this.toString();

  /// Holds current RouteNavigator - navigator is State in most of cases.
  RouteNavigator _navigator;

  /// Call this with WillPopScope Widget.
  /// return true to navigate back.
  Future<bool> navigateBack() async => true;

  /// just set RouteNavigator
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
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false}) {
    return _navigator?.openRoute(route, root: root, replacement: replacement);
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
    _navigator = null;
  }

  /// Initializes controller and pushes Route into Navigator
  /// Check openRoute for more info.
  Future<dynamic> openController(BaseController controller, {bool root: false, bool replacement: false, List args}) {
    controller.parent = this;
    if (!controller.isInitialized) {
      controller.init(args);
    }
    return openRoute(controller.getRoute(), root: root, replacement: replacement);
  }

  /// Initializes controller and pushes Route into Navigator
  /// Check openRoot for more info.
  Future<dynamic> openRootController(BaseController controller, {List args}) {
    if (!controller.isInitialized) {
      controller.init(args);
    }
    return openRoot(controller.getRoute());
  }

  /// Initializes controller and shows Dialog
  /// Check openDialog for more info.
  Future<dynamic> openDialogController(StateController controller, {bool root: false, List args}) {
    controller.parent = this;

    if (!controller.isInitialized) {
      controller.init(args);
    }

    return openDialog(controller, root: root);
  }

  @override
  Route getRoute({RouteSettings settings}) {
    //TODO: more settings
    final routeSettings = settings ?? RouteSettings(name: routeIdentifier);

    return MaterialPageRoute(settings: routeSettings, builder: (context) => getWidget());

    //just for debug
    return PageRouteBuilder(
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget child) {
                return Opacity(
                  opacity: animation.value,
                  child: getWidget(),
                );
              });
        },
        transitionDuration: Duration(milliseconds: 1000));
  }
}
