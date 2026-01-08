part of '../config.dart';

typedef ValueDelegateGetter<T> = T Function();
typedef ValueDelegateSetter<U> = void Function(U value);

/// A base class for creating reactive models that wrap preference values.
///
/// `PrefModelBase` extends [ControlModel] and mixes in [NotifierComponent],
/// allowing it to behave as an observable that can notify listeners whenever
/// the underlying preference value changes. It provides a common interface
/// for reading and writing values to e.g. [SharedPreferences].
///
/// - [T]: The type of the value read from preferences.
/// - [U]: The type of the value written to preferences.
///
/// - Check [PrefModel] and [PrefModelAsync]
class PrefModelBase<T, U> extends ControlModel with NotifierComponent {
  /// The key used to store and retrieve the preference in [SharedPreferences].
  final String key;

  final ValueDelegateGetter<T> _get;
  final ValueDelegateSetter<U> _set;

  /// The current value of the preference. Accessing this triggers the getter.
  T get value => _get();

  /// Sets a new value for the preference.
  /// This updates the stored preference and notifies all listeners via [notify()].
  set value(T? value) {
    _set(value as U);
    notify();
  }

  PrefModelBase({
    required this.key,
    required ValueDelegateGetter<T> get,
    required ValueDelegateSetter<U> set,
  })  : _set = set,
        _get = get;

  /// Clears the preference by setting its value to `null`.
  void clear() => value = null;
}

/// A concrete implementation of [PrefModelBase] for common data types.
///
/// `PrefModel` provides static factory constructors for boolean, string, integer,
/// double, dynamic data (JSON), and enum preferences, offering a reactive way
/// to interact with [SharedPreferences].
class PrefModel<T> extends PrefModelBase<T, T> {
  PrefModel({
    required super.key,
    required super.get,
    required super.set,
  });

  /// Creates a [PrefModel] for a boolean preference.
  static PrefModel<bool> boolean(String key, {bool defaultValue = false}) =>
      PrefModel<bool>(
        key: key,
        get: () =>
            PrefsProvider.instance.getBool(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.setBool(key, value),
      );

  /// Creates a [PrefModel] for a nullable string preference.
  static PrefModel<String?> string(String key, {String? defaultValue}) =>
      PrefModel<String?>(
        key: key,
        get: () => PrefsProvider.instance.get(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.set(key, value),
      );

  /// Creates a [PrefModel] for an integer preference.
  static PrefModel<int> integer(String key, {int defaultValue = 0}) =>
      PrefModel<int>(
        key: key,
        get: () =>
            PrefsProvider.instance.getInt(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.setInt(key, value),
      );

  /// Creates a [PrefModel] for a double preference.
  static PrefModel<double> number(String key, {double defaultValue = 0.0}) =>
      PrefModel<double>(
        key: key,
        get: () =>
            PrefsProvider.instance.getDouble(key, defaultValue: defaultValue),
        set: (value) => PrefsProvider.instance.setDouble(key, value),
      );

  /// Creates a [PrefModel] for dynamic data (JSON) preference.
  ///
  /// - [get]: A converter function to transform the raw JSON data into type [T].
  /// - [set]: A converter function to transform type [T] into a `Map<String, dynamic>` for storage.
  static PrefModel<T?> data<T>(String key, T Function(dynamic) get,
          Map<String, dynamic>? Function(T? value) set) =>
      PrefModel<T?>(
        key: key,
        get: () => PrefsProvider.instance.getData(key, converter: get),
        set: (value) => PrefsProvider.instance.setData(key, set(value)),
      );

  /// Creates a [PrefModel] for an enum preference.
  ///
  /// - [enums]: A list of all possible enum values for validation and conversion.
  static PrefModel<T> enums<T>(String key, List<T> enums,
          {String? defaultValue}) =>
      PrefModel<T>(
        key: key,
        get: () => Parse.toEnum<T>(
            PrefsProvider.instance.get(key, defaultValue: defaultValue), enums),
        set: (value) => PrefsProvider.instance.set(key, Parse.fromEnum(value)),
      );
}

/// A base class for reactive preference models that handle asynchronous value retrieval.
///
/// This is useful when the underlying preference storage API is inherently asynchronous
/// for both read and write operations, such as `FlutterSecureStorage`.
///
/// Example (using `FlutterSecureStorage`):
/// ```dart
/// class SecurePrefsManager {
///   final FlutterSecureStorage _storage = FlutterSecureStorage();
///
///   PrefModelAsync<String?> secureString({required String key, String? defaultValue}) =>
///       PrefModelAsync<String?>(
///         key: key,
///         get: () async => await _storage.read(key: key) ?? defaultValue,
///         set: (value) => _storage.write(key: key, value: value),
///       );
/// }
/// ```
class PrefModelAsync<T> extends PrefModelBase<Future<T>, T> {
  PrefModelAsync({
    required super.key,
    required super.get,
    required super.set,
  });
}
