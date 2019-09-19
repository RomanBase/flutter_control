import 'package:flutter_control/core.dart';

class AppControl extends InheritedWidget {
  /// Runtime Type of class.
  /// Used for custom class integration.
  static Type _accessType;

  /// returns nearest AppControl to given context.
  /// nullable
  static AppControl of(BuildContext context) {
    if (context != null) {
      final control = context.inheritFromWidgetOfExactType(_accessType);

      if (control != null) {
        return control;
      }
    }

    return ControlProvider.of(ControlKey.control);
  }

  /// Holds current locale.
  final String locale;

  /// Key of root State.
  final GlobalKey rootKey;

  /// Global key of [AppControl]
  GlobalKey get mainKey => key;

  /// Holder of current root context.
  /// Don't get/set context directly - use [rootContext] instead.
  final ContextHolder contextHolder;

  /// Returns current context from [contextHolder]
  BuildContext get rootContext => contextHolder.context;

  /// Sets new root context to [contextHolder]
  set rootContext(BuildContext context) => contextHolder.changeContext(context);

  final StateNotifier rootState;

  /// Holds global [State] and root [BuildContext].
  /// Root context can be changed via [rootContext].
  AppControl({
    @required this.rootKey,
    @required this.contextHolder,
    this.locale,
    this.rootState,
    Widget child,
  }) : super(key: GlobalKey(), child: child) {
    assert(rootKey != null);
    assert(contextHolder != null);

    _accessType = this.runtimeType;

    ControlFactory.of(this).addItem(ControlKey.control, this);
  }

  void notifyAppState([dynamic state]) {
    if (rootState != null) {
      rootState.notifyState(state);
    } else {
      printDebug('no root state specified');
    }
  }

  @override
  bool updateShouldNotify(AppControl oldWidget) {
    return locale != oldWidget.locale;
  }
}
