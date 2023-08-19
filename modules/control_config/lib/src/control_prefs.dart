part of control_config;

/// Wrapper around [SharedPreferences].
class ControlPrefs {
  SharedPreferences? prefs;

  bool get mounted => prefs != null;

  Future<ControlPrefs> init() async {
    await mount();
    return this;
  }

  Future<SharedPreferences?> mount() async {
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

  void set(String key, String? value) => prefs?.setString(key, value ?? '');

  String? get(String key, {String? defaultValue}) {
    final result = prefs?.getString(key);

    if (result == null || result.isEmpty) {
      return defaultValue;
    }

    return result;
  }

  void setBool(String key, bool? value) => prefs?.setBool(key, value ?? false);

  bool getBool(String key, {bool defaultValue = false}) =>
      prefs?.getBool(key) ?? defaultValue;

  void setInt(String key, int? value) => prefs?.setInt(key, value ?? 0);

  int getInt(String key, {int defaultValue = 0}) =>
      prefs?.getInt(key) ?? defaultValue;

  void setDouble(String key, double? value) =>
      prefs?.setDouble(key, value ?? 0.0);

  double getDouble(String key, {double defaultValue = 0.0}) =>
      prefs?.getDouble(key) ?? defaultValue;

  void setJson(String key, dynamic value) =>
      prefs?.setString(key, jsonEncode(value ?? {}));

  dynamic getJson(String key) => jsonDecode(get(key, defaultValue: '{}')!);
}

mixin PrefsProvider {
  static ControlPrefs get instance => Control.get<ControlPrefs>()!;

  ControlPrefs get prefs => instance;
}
