import 'package:flutter_control/core.dart';

/// Lazily build value once and holds it for whole time.
class InitHolder<T> {
  /// Current value.
  T _value;

  /// Current value builder.
  ValueGetter<T> _builder;

  /// Checks if builder is valid.
  bool get isActive => _builder != null;

  /// Checks if value is build.
  bool get isBuild => _value != null;

  /// Default constructor
  InitHolder({ValueGetter<T> builder}) {
    _builder = builder;
  }

  /// Sets builder if none [isActive].
  /// [override] to override current builder even if [isActive] and clears current value.
  bool set({@required ValueGetter<T> builder, bool override: false}) {
    if (_builder == null || override) {
      _value = null;
      _builder = builder;
      return true;
    }

    return false;
  }

  /// Returns current value or build new one and store it for later get.
  T get() => _value ?? (_value = _builder());
}
