import 'dart:convert';

import 'package:flutter_control/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around [SharedPreferences].
class BasePrefs {
  SharedPreferences prefs;

  bool get mounted => prefs != null;

  Future<BasePrefs> init() async {
    await mount();
    return this;
  }

  Future<SharedPreferences> mount() async {
    if (!mounted) {
      //impossible to mount in pure Dart environment..
      //only iOS and Android right now..
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        printDebug(e.toString());
      }
    }

    return prefs;
  }

  void set(String key, String value) => prefs?.setString(key, value);

  String get(String key, {String defaultValue}) => prefs?.getString(key) ?? defaultValue;

  void setBool(String key, bool value) => prefs?.setBool(key, value);

  bool getBool(String key, {bool defaultValue: true}) => prefs?.getBool(key) ?? defaultValue;

  void setInt(String key, int value) => prefs?.setInt(key, value);

  int getInt(String key, {int defaultValue: 0}) => prefs?.getInt(key) ?? defaultValue;

  void setDouble(String key, double value) => prefs?.setDouble(key, value);

  double getDouble(String key, {double defaultValue: 0.0}) => prefs?.getDouble(key) ?? defaultValue;

  void json(String key, dynamic value) => prefs?.setString(key, jsonEncode(value));

  dynamic getJson(String key) => jsonDecode(get(key, defaultValue: '{}'));
}

mixin PrefsProvider {
  BasePrefs _prefs;

  BasePrefs get prefs => _prefs ?? (_prefs = Control.get<BasePrefs>() ?? BasePrefs());

  static Future<BasePrefs> init() => (Control.get<BasePrefs>() ?? BasePrefs()).init();
}
