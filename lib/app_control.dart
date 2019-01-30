import 'package:flutter_control/core.dart';

/// One of the root Widgets of App.
/// Initializes with GlobalKey and BuildContext of root Widgets (Scaffold is recommended).
/// AppControl can hold important objects to use them anywhere in App.
/// Custom localization is used here. For more info check AppLocalization class.
class AppControl extends InheritedWidget {
  /// Runtime Type of class.
  /// Used for custom class integration.
  static Type _accessType;

  /// Key of root State.
  final GlobalKey rootKey;

  /// Context of root Scaffold.
  final ContextHolder contextHolder;

  /// Locale of current App.
  final String iso2Locale;

  /// Root context of App (root Scaffold).
  /// Mainly used for Navigator and Dialogs.
  BuildContext get context => contextHolder.context;

  /// returns nearest AppControl to given context.
  /// nullable
  static AppControl of(BuildContext context) {
    if (context == null) {
      return null;
    }

    return context.inheritFromWidgetOfExactType(_accessType);
  }

  /// returns instance of AppFactory.
  /// context is currently ignored.
  /// nullable
  static AppFactory factory([dynamic context]) => AppFactory.of(context);

  /// returns instance of AppLocalization
  /// context is currently ignored
  /// nullable
  static AppLocalization localization([dynamic context]) => factory(context)?.getItem('localization');

  /// Default constructor
  AppControl({Key key, @required this.rootKey, @required this.contextHolder, this.iso2Locale, List<LocalizationAsset> locales, Map<String, dynamic> entries, Map<Type, Getter> initializers, Widget child}) : super(key: key, child: child) {
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

    entries['control'] = this;
    entries['localization'] = AppLocalization(iso2Locale ?? locales[0].iso2Locale, locales);

    factory(this).init(items: entries, initializers: initializers);

    contextHolder.once((context) => localization(this)?.changeLocale(iso2Locale));
  }

  /// Changes localization of all sub widgets (typically whole app).
  /// It can take a while because localization is loaded from json file.
  Future<bool> changeLocale(String iso2Locale) {
    return localization(this)?.changeLocale(iso2Locale);
  }

  @override
  bool updateShouldNotify(AppControl oldWidget) {
    return iso2Locale != oldWidget.iso2Locale;
  }
}
