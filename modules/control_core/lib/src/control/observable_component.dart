part of '../../core.dart';

/// A mixin that adds [ObservableValue] capabilities to a [ControlModel].
///
/// By using this mixin, a `ControlModel` can hold a value and notify listeners
/// whenever it changes, effectively becoming a self-contained piece of reactive state.
///
/// Example:
/// ```dart
/// class CounterModel extends BaseModel with ObservableComponent<int> {
///   CounterModel() {
///     value = 0; // Set initial value
///   }
///
///   void increment() {
///     value = (value ?? 0) + 1;
///   }
/// }
/// ```
mixin ObservableComponent<T> on ControlModel
    implements ObservableValue<T?>, ObservableNotifier {
  /// Actual observable to subscribe.
  final _parent = ControlObservable.empty<T>();

  @override
  dynamic internalData;

  @override
  T? get value => _parent.value;

  set value(T? value) => _parent.value = value;

  void setValue(T? value, {bool notify = true, bool forceNotify = false}) =>
      _parent.setValue(
        value,
        notify: notify,
        forceNotify: forceNotify,
      );

  @override
  ControlSubscription<T?> listen(VoidCallback action) =>
      subscribe((_) => action());

  @override
  ControlSubscription<T?> subscribe(ValueCallback<T?> action,
          {bool current = true, dynamic args}) =>
      _parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription<T?> subscription) =>
      _parent.cancel(subscription);

  @override
  void notify() => _parent.notify();

  @protected
  ControlSubscription<U> wrap<U>(ObservableValue<U> other,
          {T Function(U value)? converter, bool autoDispose = true}) =>
      _parent.wrap(other, converter: converter, autoDispose: autoDispose);

  @override
  void dispose() {
    super.dispose();

    _parent.dispose();
  }
}

/// A mixin that adds [ObservableChannel] capabilities to a [ControlModel].
///
/// This turns a model into a notification channel that can signal events to listeners
/// without carrying a specific data value.
///
/// Example:
/// ```dart
/// class FormModel extends BaseModel with NotifierComponent {
///   void submit() {
///     //... form submission logic
///     notify(); // Signal that the form has been submitted.
///   }
/// }
/// ```
mixin NotifierComponent on ControlModel
    implements ObservableChannel, ObservableNotifier {
  /// Actual control to subscribe.
  final _parent = ControlObservable.empty();

  @override
  dynamic internalData;

  @override
  ControlSubscription<void> listen(VoidCallback action) => subscribe(action);

  @override
  ControlSubscription<void> subscribe(VoidCallback action,
          {bool current = false, args}) =>
      _parent.subscribe(
        (_) => action.call(),
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription subscription) => _parent.cancel(subscription);

  @override
  void notify() => _parent.notify();

  @protected
  ControlSubscription<U> wrap<U>(ObservableValue<U> other,
          {bool autoDispose = true}) =>
      _parent.wrap(other, autoDispose: autoDispose);

  @override
  void dispose() {
    super.dispose();

    _parent.dispose();
  }
}
