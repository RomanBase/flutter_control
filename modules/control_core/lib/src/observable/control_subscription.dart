part of '../../core.dart';

/// Subscription part of [ObservableValue].
/// Since [invalidate] is introduced, [dispose] is ignored by [ControlObservable].
class ControlSubscription<T> implements Disposable {
  /// Reference to Observable.
  ObservableValue? _parent;

  /// Callback function no notify when observable is changed.
  ValueCallback<T>? _callback;

  /// Test until this sub is valid.
  Predicate<T>? _until;

  /// Test to filter observable values.
  Predicate<T>? _filter;

  /// Checks if this subscription is active.
  bool _active = true;

  /// Checks if observable is set.
  bool get isValid => _parent != null;

  /// Checks is this subscription can serve.
  bool get isActive => isValid && _active;

  /// Checks if callback to serve is available.
  bool get isCallbackAttached => _callback != null;

  /// Activate this subscription.
  /// Given [callback] will serve changes via observable.
  void initSubscription(ObservableValue parent, [ValueCallback<T>? callback]) {
    _parent = parent;
    _callback = callback;
  }

  /// Sets test to [filter] observable values.
  ControlSubscription<T> filter(Predicate<T>? filter) {
    _filter = filter;
    return this;
  }

  /// Sets test to [predicate] when to cancel this subscription.
  ControlSubscription<T> until(Predicate<T>? predicate) {
    _until = predicate;
    return this;
  }

  /// Serve just one change. After this subscription cancels.
  ControlSubscription<T> once() {
    _until = (value) => true;
    return this;
  }

  /// Checks if sub will accept this value.
  bool _filterPass(T value) => _filter?.call(value) ?? true;

  /// Checks if is time to close this subscription.
  bool _closePass(T value) => _until?.call(value) ?? false;

  /// Notify sub with given [value].
  /// Check [filter] and [until] to modify callback.
  /// When sub is ready to [invalidate], then parent observer will remove sub from its listeners.
  void notifyCallback(T value) {
    if (!isActive || !_filterPass(value)) {
      return;
    }

    _callback?.call(value);

    if (_closePass(value)) {
      invalidate();
    }
  }

  void pause() => _active = false;

  void resume() => _active = isValid;

  void cancel() {
    _active = false;
    _parent?.cancel(this);

    invalidate();
  }

  void invalidate() {
    _active = false;
    _parent = null;
    _callback = null;
  }

  @override
  void dispose() {
    if (isValid) {
      cancel();
    }
  }
}
