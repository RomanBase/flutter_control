import 'package:flutter_control/core.dart';

class AppControl extends InheritedWidget {
  static Type _accessType;

  final GlobalKey rootKey;
  final ContextHolder contextHolder;
  final AppLocalization localization;
  final _items = Map<String, dynamic>();

  BuildContext get context => contextHolder.context;

  static AppControl of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(_accessType);
  }

  AppControl({@required this.rootKey, @required this.contextHolder, Key key, this.localization, Widget child, Map<String, dynamic> entries}) : super(key: key, child: child) {
    _accessType = this.runtimeType;

    if(entries != null){
      _items.addAll(entries);
    }
  }

  void addItem(String key, dynamic object) {
    _items[key] = object;
  }

  T getItem<T>(String key) {
    return _items[key] as T;
  }

  T removeItem<T>(String key) {
    return _items.remove(key) as T;
  }

  Future<bool> changeLocale(String iso2Locale) {
    return localization.changeLocale(iso2Locale);
  }

  String localize(String key) {
    return localization.localize(key);
  }

  String extractLocalization(Map<String, String> map) {
    return localization.extractLocalization(map, localization.locale, localization.defaultLocale);
  }

  @override
  bool updateShouldNotify(AppControl oldWidget) {
    return localization.locale != oldWidget.localization.locale;
  }
}
