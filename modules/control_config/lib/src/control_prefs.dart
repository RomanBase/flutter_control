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

  void setBool(String key, bool? value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) =>
      prefs?.getBool(key) ?? defaultValue;

  void setInt(String key, int? value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) =>
      prefs?.getInt(key) ?? defaultValue;

  void setDouble(String key, double? value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) =>
      prefs?.getDouble(key) ?? defaultValue;

  void setJson(String key, dynamic value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setString(key, jsonEncode(value));
  }

  T? getJson<T>(String key, {ValueConverter<T>? converter}) {
    final raw = get(key);

    if (raw == null) {
      return null;
    }

    final json = jsonDecode(raw);

    if (converter == null) {
      return json;
    }

    return converter.call(json);
  }
}

mixin PrefsProvider {
  static ControlPrefs get instance => Control.use<ControlPrefs>(value: () => ControlPrefs());

  ControlPrefs get prefs => instance;
}
