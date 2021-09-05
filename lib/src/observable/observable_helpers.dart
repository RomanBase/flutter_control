import 'package:flutter_control/core.dart';

mixin ObservableNBoolMixin on ObservableModel<bool?> {
  /// Checks if [value] is 'true'.
  bool get isTrue => value == true;

  /// Checks if [value] is 'false' or 'null'.
  bool get isFalse => value == false || value == null;

  /// Toggles current value and notifies listeners.
  /// 'null' -> 'true'
  /// 'true' -> 'false'
  /// 'false' -> 'true'
  bool toggle() {
    setValue(value == null ? true : !value!);

    return value!;
  }

  /// Sets value to 'true'.
  /// Listeners are notified if [value] is changed.
  void setTrue() => setValue(true);

  /// Sets value to 'false'.
  /// Listeners are notified if [value] is changed.
  void setFalse() => setValue(false);
}

mixin ObservableBoolMixin on ObservableModel<bool> {
  /// Checks if [value] is 'true'.
  bool get isTrue => value == true;

  /// Checks if [value] is 'false' or 'null'.
  bool get isFalse => value == false;

  /// Toggles current value and notifies listeners.
  /// 'true' -> 'false'
  /// 'false' -> 'true'
  bool toggle() {
    setValue(!value);

    return value;
  }

  /// Sets value to 'true'.
  /// Listeners are notified if [value] is changed.
  void setTrue() => setValue(true);

  /// Sets value to 'false'.
  /// Listeners are notified if [value] is changed.
  void setFalse() => setValue(false);
}
