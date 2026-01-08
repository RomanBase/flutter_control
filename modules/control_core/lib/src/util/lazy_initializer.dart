part of '../../core.dart';

/// Lazily builds and caches a value. The value is created only once on the first access.
///
/// @deprecated This class is not actively used and will be removed in a future version.
/// Consider using `lazy` property patterns or `ControlFactory` for lazy initialization.
@Deprecated('Will be removed in future')
class LazyInitializer<T> {
  /// Current value.
  T? _value;

  /// Current value builder.
  ValueGetter<T>? _builder;

  /// Checks if builder is valid.
  bool get isActive => _builder != null;

  /// Checks if value is build.
  bool get isBuild => _value != null;

  bool _isDirty = true;

  /// Is true if current [internalData] needs rebuild.
  bool get isDirty => _isDirty || !isActive;

  /// Default constructor
  LazyInitializer({ValueGetter<T>? builder}) {
    _builder = builder;
  }

  /// Sets builder if none [isActive].
  /// [override] to override current builder even if [isActive] and clears current value.
  bool set({required ValueGetter<T> builder, bool override = false}) {
    if (isDirty || override) {
      _value = null;
      _isDirty = false;
      _builder = builder;
      return true;
    }

    return false;
  }

  /// Returns the cached value. If the value has not been created yet,
  /// it calls the builder, caches the result, and then returns it.
  T get() => _value ?? (_value = _builder!());

  /// Sets holder to dirty, so next [set] will override builder.
  void setDirty() => _isDirty = true;

  /// Removes value from holder, so next [get] will trigger builder.
  void requestRebuild() => _value = null;
}
