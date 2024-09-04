part of '../../core.dart';

extension ObservableBoolExt on ObservableModel<bool> {
  /// Checks if [value] is 'true'.
  bool get isTrue => value == true;

  /// Checks if [value] is 'false' or 'null'.
  bool get isFalse => value != true;

  /// Toggles current value and notifies listeners.
  /// 'true' -> 'false'
  /// 'false' -> 'true'
  bool toggle() {
    setValue(isTrue ? false : true);

    return value;
  }

  /// Sets value to 'true'.
  /// Listeners are notified if [value] is changed.
  void setTrue() => setValue(true);

  /// Sets value to 'false'.
  /// Listeners are notified if [value] is changed.
  void setFalse() => setValue(false);
}
