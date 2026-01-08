part of '../config.dart';

/// A robust wrapper around [SharedPreferences] for simplified and type-safe data persistence.
///
/// `ControlPrefs` handles common operations like setting and getting various data types
/// (`String`, `bool`, `int`, `double`, `dynamic` for JSON), and provides methods
/// for checking key existence and removal.
///
/// It must be initialized via `init()` or `mount()` before use.
class ControlPrefs {
  /// The underlying [SharedPreferences] instance.
  SharedPreferences? prefs;

  /// Returns `true` if [SharedPreferences] has been successfully mounted.
  bool get mounted => prefs != null;

  /// Initializes `ControlPrefs` by mounting [SharedPreferences].
  /// Call this once before using any preference operations.
  Future<ControlPrefs> init() async {
    await mount();
    return this;
  }

  /// Asynchronously gets and sets up the [SharedPreferences] instance.
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

  /// Checks if a key exists in preferences.
  bool contains(String key) => prefs?.containsKey(key) ?? false;

  /// Removes a key-value pair from preferences.
  void remove(String key) => prefs?.remove(key);

  /// Sets a string [value] for the given [key]. If [value] is `null`, the key is removed.
  void set(String key, String? value) => prefs?.setString(key, value ?? '');

  /// Gets a string value for the given [key]. Returns [defaultValue] if not found or empty.
  String? get(String key, {String? defaultValue}) {
    final result = prefs?.getString(key);

    if (result == null || result.isEmpty) {
      return defaultValue;
    }

    return result;
  }

  /// Sets a boolean [value] for the given [key]. If [value] is `null`, the key is removed.
  void setBool(String key, bool? value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setBool(key, value);
  }

  /// Gets a boolean value for the given [key]. Returns [defaultValue] if not found.
  bool getBool(String key, {bool defaultValue = false}) =>
      prefs?.getBool(key) ?? defaultValue;

  /// Sets an integer [value] for the given [key]. If [value] is `null`, the key is removed.
  void setInt(String key, int? value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setInt(key, value);
  }

  /// Gets an integer value for the given [key]. Returns [defaultValue] if not found.
  int getInt(String key, {int defaultValue = 0}) =>
      prefs?.getInt(key) ?? defaultValue;

  /// Sets a double [value] for the given [key]. If [value] is `null`, the key is removed.
  void setDouble(String key, double? value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setDouble(key, value);
  }

  /// Gets a double value for the given [key]. Returns [defaultValue] if not found.
  double getDouble(String key, {double defaultValue = 0.0}) =>
      prefs?.getDouble(key) ?? defaultValue;

  /// Stores a dynamic [value] as a JSON string for the given [key].
  /// If [value] is `null`, the key is removed.
  void setData(String key, dynamic value) {
    if (value == null) {
      prefs?.remove(key);
      return;
    }

    prefs?.setString(key, jsonEncode(value));
  }

  /// Retrieves a JSON-encoded value for the given [key] and optionally converts it to type [T].
  /// Returns `null` if the key is not found or parsing fails.
  T? getData<T>(String key, {ValueConverter<T>? converter}) {
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

/// A mixin that provides easy access to the [ControlPrefs] instance.
///
/// By mixing `PrefsProvider` into any class, you gain convenient access to
/// the global `ControlPrefs` instance via the `prefs` getter.
mixin PrefsProvider {
  /// Retrieves the singleton instance of [ControlPrefs] from the [ControlFactory].
  /// If `ControlPrefs` is not yet registered, it attempts to create and register it.
  static ControlPrefs get instance =>
      Control.use<ControlPrefs>(value: () => ControlPrefs());

  /// Provides direct access to the [ControlPrefs] instance.
  ControlPrefs get prefs => instance;
}
