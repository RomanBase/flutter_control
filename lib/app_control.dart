import 'package:flutter_control/core.dart';

/// One of the root Widgets of App.
/// Initializes with GlobalKey and BuildContext of root Widgets (Scaffold is recommended).
/// AppControl can hold important objects to use them anywhere in App.
/// Custom localization is used here. For more info check AppLocalization class.
class AppControl extends InheritedWidget {
  /// Runtime Type of class.
  /// Used for custom class integration.
  static Type _accessType;

  /// Key of root State
  final GlobalKey rootKey;

  /// Context of root Scaffold
  final ContextHolder contextHolder;

  /// Custom localization.
  final AppLocalization localization;

  /// Stored objects for global use.
  final _items = Map<String, dynamic>();

  /// Root context of App (root Scaffold).
  /// Mainly used for Navigator and Dialogs
  BuildContext get context => contextHolder.context;

  /// returns nearest AppControl to given context.
  /// nullable
  static AppControl of(BuildContext context) {
    if (context == null) {
      return null;
    }

    return context.inheritFromWidgetOfExactType(_accessType);
  }

  /// Default constructor
  AppControl({@required this.rootKey, @required this.contextHolder, Key key, this.localization, Widget child, Map<String, dynamic> entries}) : super(key: key, child: child) {
    _accessType = this.runtimeType;

    if (entries != null) {
      _items.addAll(entries);
    }
  }

  /// Adds object with given key for global use.
  void addItem(String key, dynamic object) {
    _items[key] = object;
  }

  /// returns object of requested type by given key.
  /// Can be null.
  T getItem<T>(String key) {
    return _items[key] as T;
  }

  /// returns object of requested type.
  /// Can be null.
  T getItemByType<T>(Type type) {
    for (final item in _items.values) {
      if (item.runtimeType == type) {
        return item as T;
      }
    }

    return null;
  }

  /// removes item of given key.
  T removeItem<T>(String key) {
    return _items.remove(key) as T;
  }

  /// removes all items of given type
  void removeItemByType(Type type) {
    _items.removeWhere((key, item) => item.runtimeType == type);
  }

  /// Changes localization of all sub widgets (typically whole app).
  /// It can take a while because localization is loaded from json file.
  Future<bool> changeLocale(String iso2Locale) {
    return localization?.changeLocale(iso2Locale);
  }

  /// Tries to localize text by given key.
  String localize(String key) {
    return localization?.localize(key);
  }

  /// Tries to localize text by given key.
  String extractLocalization(Map<String, String> map) {
    return localization?.extractLocalization(map, localization.locale, localization.defaultLocale);
  }

  @override
  bool updateShouldNotify(AppControl oldWidget) {
    return localization?.locale != oldWidget.localization?.locale;
  }
}
