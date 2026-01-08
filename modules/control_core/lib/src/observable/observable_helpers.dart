part of '../../core.dart';

/// An extension on `ObservableModel<bool>` providing convenience methods
/// for working with boolean observables.
extension ObservableBoolExt on ObservableModel<bool> {
  /// Checks if the observable's current value is `true`.
  bool get isTrue => value == true;

  /// Checks if the observable's current value is `false` or `null`.
  bool get isFalse => value != true;

  /// Toggles the boolean value (`true` to `false`, or `false`/`null` to `true`)
  /// and notifies listeners.
  ///
  /// Returns the new value.
  bool toggle() {
    setValue(isTrue ? false : true);

    return value;
  }

  /// Sets the observable's value to `true` and notifies listeners.
  void setTrue() => setValue(true);

  /// Sets the observable's value to `false` and notifies listeners.
  void setFalse() => setValue(false);
}
