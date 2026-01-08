part of '../../core.dart';

/// Represents a subscription to an [ObservableValue].
///
/// A subscription is created when you `listen` or `subscribe` to an observable.
/// It holds the callback to be executed and provides methods to control the
/// subscription's lifecycle and behavior, such as filtering events or unsubscribing.
///
/// While `dispose()` can be called to manually cancel, the subscription is usually
/// managed by its parent observable.
class ControlSubscription<T> implements Disposable {
  /// A reference to the parent observable this subscription is attached to.
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

  /// Activates the subscription by linking it to a parent observable and setting a callback.
  ///
  /// This is called internally by the observable when a subscription is created.
  void initSubscription(ObservableValue parent, [ValueCallback<T>? callback]) {
    _parent = parent;
    _callback = callback;
  }

  /// Applies a filter to the subscription.
  ///
  /// The subscription's callback will only be invoked if the new value
  /// passes the [filter] predicate.
  ControlSubscription<T> filter(Predicate<T>? filter) {
    _filter = filter;
    return this;
  }

  /// Sets a condition to automatically cancel the subscription.
  ///
  /// The subscription will be canceled after receiving the first value
  /// for which the [predicate] returns `true`.
  ControlSubscription<T> until(Predicate<T>? predicate) {
    _until = predicate;
    return this;
  }

  /// Configures the subscription to be canceled after the first notification.
  ControlSubscription<T> once() {
    _until = (value) => true;
    return this;
  }

  /// Checks if sub will accept this value.
  bool _filterPass(T value) => _filter?.call(value) ?? true;

  /// Checks if is time to close this subscription.
  bool _closePass(T value) => _until?.call(value) ?? false;

  /// Notifies the subscription with a new value.
  ///
  /// This is called by the parent observable. It respects the [filter] and [until]
  /// conditions before invoking the callback.
  void notifyCallback(T value) {
    if (!isActive || !_filterPass(value)) {
      return;
    }

    _callback?.call(value);

    if (_closePass(value)) {
      invalidate();
    }
  }

  /// Pauses the subscription, temporarily stopping notifications.
  void pause() => _active = false;

  /// Resumes a paused subscription.
  void resume() => _active = isValid;

  /// Cancels the subscription and removes it from the parent observable.
  void cancel() {
    _active = false;
    _parent?.cancel(this);

    invalidate();
  }

  /// Marks the subscription as invalid, detaching it from its parent and callback.
  ///
  /// This is used by the parent observable to clean up subscriptions.
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
