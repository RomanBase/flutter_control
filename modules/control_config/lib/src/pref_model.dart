part of control_config;

ControlPrefs get _prefs => PrefsProvider.instance;

class PrefModel<T> {
  final String key;
  final T? defaultValue;

  final ValueGetter<T> get;
  final ValueSetter<T?> set;

  T get value => get();

  set value(T? value) => set(value);

  const PrefModel({
    required this.key,
    this.defaultValue,
    required this.get,
    required this.set,
  });

  void clear() => _prefs.set(key, null);

  static PrefModel<bool> boolean(String key, {bool defaultValue = false}) =>
      PrefModel<bool>(
        key: key,
        get: () => _prefs.getBool(key, defaultValue: defaultValue),
        set: (value) => _prefs.setBool(key, value),
      );

  static PrefModel<String?> string(String key, {String? defaultValue}) =>
      PrefModel<String?>(
        key: key,
        get: () => _prefs.get(key, defaultValue: defaultValue),
        set: (value) => _prefs.set(key, value),
      );

  static PrefModel<T> object<T>(String key, List<T> enums,
          {String? defaultValue}) =>
      PrefModel<T>(
        key: key,
        get: () =>
            Parse.toEnum<T>(_prefs.get(key, defaultValue: defaultValue), enums),
        set: (value) => _prefs.set(key, Parse.fromEnum(value)),
      );

  static PrefModel<int> integer(String key, {int defaultValue = 0}) =>
      PrefModel<int>(
        key: key,
        get: () => _prefs.getInt(key, defaultValue: defaultValue),
        set: (value) => _prefs.setInt(key, value),
      );

  static PrefModel<double> number(String key, {double defaultValue = 0.0}) =>
      PrefModel<double>(
        key: key,
        get: () => _prefs.getDouble(key, defaultValue: defaultValue),
        set: (value) => _prefs.setDouble(key, value),
      );

  static PrefModel<T?> data<T>(String key, T Function(dynamic) get,
          Map<String, dynamic>? Function(T? value) set) =>
      PrefModel<T?>(
        key: key,
        get: () => _prefs.getJson(key, converter: get),
        set: (value) => _prefs.setJson(key, set(value)),
      );
}
