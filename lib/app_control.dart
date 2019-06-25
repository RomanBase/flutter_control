import 'dart:async';

import 'package:flutter_control/app_prefs.dart';
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

    return factory(context).get(FactoryKey.control);
  }

  /// returns instance of AppFactory.
  /// context is currently ignored.
  /// nullable
  static AppFactory factory([dynamic context]) => AppFactory.of(context);

  /// returns instance of AppLocalization
  /// context is currently ignored
  /// nullable
  static AppLocalization localization([dynamic context]) => factory(context)?.get(FactoryKey.localization);

  /// returns instance of AppPrefs
  /// context is currently ignored
  /// nullable
  static AppPrefs prefs([dynamic context]) => factory(context)?.get(FactoryKey.preferences);

  /// Returns current locale.
  String get iso2Locale => localization(this)?.locale;

  /// Key of root State.
  final GlobalKey rootKey;

  /// Holder of current root context.
  /// Don't get/set context directly - use [rootContext] instead.
  final ContextHolder contextHolder;

  /// Returns current context from [contextHolder]
  BuildContext get rootContext => contextHolder.context;

  /// Sets new root context to [contextHolder]
  set rootContext(BuildContext context) => contextHolder.changeContext(context);

  /// Default constructor
  AppControl({
    Key key,
    @required this.rootKey,
    @required this.contextHolder,
    String defaultLocale,
    List<LocalizationAsset> locales,
    Map<String, dynamic> entries,
    Map<Type, Getter> initializers,
    Widget child,
    bool debug,
  }) : super(key: key, child: child) {
    assert(rootKey != null);
    assert(contextHolder != null);

    _accessType = this.runtimeType;

    if (entries == null) {
      entries = Map<String, dynamic>();
    }

    if (locales == null || locales.isEmpty) {
      locales = List<LocalizationAsset>();
      locales.add(LocalizationAsset('en', null));
    }

    entries[FactoryKey.control] = this;
    entries[FactoryKey.preferences] = AppPrefs();
    entries[FactoryKey.localization] = AppLocalization(defaultLocale ?? locales[0].iso2Locale, locales);

    factory(this).initialize(items: entries, initializers: initializers);
    localization(this).debug = debug ?? debugMode;

    contextHolder.once((context) {
      localization(this).changeToSystemLocale(context);
    });
  }

  /// Changes localization of all sub widgets (typically whole app).
  /// It can take a while because localization is loaded from json file.
  Future<bool> changeLocale(String iso2Locale, {VoidCallback onChanged}) async {
    return await localization(this)?.changeLocale(iso2Locale, onChanged: onChanged);
  }

  @override
  bool updateShouldNotify(AppControl oldWidget) {
    return iso2Locale != oldWidget.iso2Locale;
  }
}
