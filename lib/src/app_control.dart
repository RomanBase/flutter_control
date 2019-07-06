import 'package:flutter_control/core.dart';

class FactoryKey {
  static const String localization = 'localization';
  static const String preferences = 'prefs';
  static const String control = 'control';
}

/// One of the root Widgets of App.
/// Initializes with GlobalKey and BuildContext of root Widgets (Scaffold is recommended).
/// AppControl can hold important objects to use them anywhere in App.
/// Custom localization is used here. For more info check AppLocalization class.
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

    return ControlProvider.of(FactoryKey.control);
  }

  /// Returns current locale.
  String get iso2Locale => ControlProvider.of(FactoryKey.localization)?.locale;

  /// Key of root State.
  final GlobalKey rootKey;

  /// Holder of current root context.
  /// Don't get/set context directly - use [rootContext] instead.
  final ContextHolder contextHolder;

  /// Returns current context from [contextHolder]
  BuildContext get rootContext => contextHolder.context;

  /// Sets new root context to [contextHolder]
  set rootContext(BuildContext context) => contextHolder.changeContext(context);

  /// overrides [debugMode] to debug App in profiling and release mode.
  final debug;

  /// Default constructor
  AppControl({
    Key key,
    @required this.rootKey,
    @required this.contextHolder,
    Widget child,
    this.debug: true,
  }) : super(key: key, child: child) {
    assert(rootKey != null);
    assert(contextHolder != null);

    _accessType = this.runtimeType;
  }

  @override
  bool updateShouldNotify(AppControl oldWidget) {
    return iso2Locale != oldWidget.iso2Locale;
  }
}
