part of control_config;

typedef ValueDelegateGetter<T> = T Function();
typedef ValueDelegateSetter<T> = void Function(T value);

class PrefModelBase<T, U> implements Listenable {
  final String key;

  final _listeners = <VoidCallback>[];

  final ValueDelegateGetter<T> _get;
  final ValueDelegateSetter<U> _set;

  T get value => _get();

  set value(dynamic value) {
    _set(value as U);
    notify();
  }

  PrefModelBase({
    required this.key,
    required ValueDelegateGetter<T> get,
    required ValueDelegateSetter<U> set,
  })  : _set = set,
        _get = get;

  void clear() => value = null;

  void notify() => _listeners.forEach((listener) => listener());

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}

class PrefModel<T> extends PrefModelBase<T, T> {
  PrefModel({
    required super.key,
    required super.get,
    required super.set,
  });

  static PrefModel<bool> boolean(String key, {bool defaultValue = false}) =>
      PrefModel<bool>(
        key: key,
        get: () =>
            PrefsProvider.instance.getBool(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.setBool(key, value),
      );

  static PrefModel<String?> string(String key, {String? defaultValue}) =>
      PrefModel<String?>(
        key: key,
        get: () => PrefsProvider.instance.get(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.set(key, value),
      );

  static PrefModel<int> integer(String key, {int defaultValue = 0}) =>
      PrefModel<int>(
        key: key,
        get: () =>
            PrefsProvider.instance.getInt(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.setInt(key, value),
      );

  static PrefModel<double> number(String key, {double defaultValue = 0.0}) =>
      PrefModel<double>(
        key: key,
        get: () =>
            PrefsProvider.instance.getDouble(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.setDouble(key, value),
      );

  static PrefModel<T?> data<T>(String key, T Function(dynamic) get,
          Map<String, dynamic>? Function(T? value) set) =>
      PrefModel<T?>(
        key: key,
        get: () => PrefsProvider.instance.getData(key, converter: get),
        set: (value) => PrefsProvider.instance.setData(key, set(value)),
      );

  static PrefModel<T> enums<T>(String key, List<T> enums,
          {String? defaultValue}) =>
      PrefModel<T>(
        key: key,
        get: () => Parse.toEnum<T>(
            PrefsProvider.instance.get(key, defaultValue: defaultValue), enums),
        set: (value) => PrefsProvider.instance.set(key, Parse.fromEnum(value)),
      );
}

class PrefModelAsync<T> extends PrefModelBase<Future<T>, T> {
  PrefModelAsync({
    required super.key,
    required super.get,
    required super.set,
  });
}
