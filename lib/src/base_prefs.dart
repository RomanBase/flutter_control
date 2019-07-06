import 'dart:async';

import 'package:flutter_control/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BasePrefs {
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  Future<void> set(String key, String value) async => (await prefs).setString(key, value);

  Future<String> get(String key, {String defaultValue}) async => (await prefs).getString(key) ?? defaultValue;

  Future<void> setBool(String key, bool value) async => (await prefs).setBool(key, value);

  Future<bool> getBool(String key, {bool defaultValue: true}) async => (await prefs).getBool(key) ?? defaultValue;

  Future<void> setInt(String key, int value) async => (await prefs).setInt(key, value);

  Future<int> getInt(String key, {int defaultValue: 0}) async => (await prefs).getInt(key) ?? defaultValue;

  Future<void> setDouble(String key, double value) async => (await prefs).setDouble(key, value);

  Future<double> getDouble(String key, {double defaultValue: 0.0}) async => (await prefs).getDouble(key) ?? defaultValue;
}

mixin PrefsProvider {
  BasePrefs get prefs => ControlProvider.of(FactoryKey.preferences);
}
