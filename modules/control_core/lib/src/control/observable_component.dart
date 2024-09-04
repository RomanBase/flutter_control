part of '../../core.dart';

class ObservableLeaf<T> {
  final ObservableNotifier _parent;

  T? _value;

  T? get value => _value;

  set value(T? value) {
    _value = value;
    _parent.notify();
  }

  bool get isEmpty => _value == null;

  bool get isNotEmpty => _value != null;

  ObservableLeaf(this._parent, [this._value]);
}

mixin ObservableComponent<T> on ControlModel
    implements ObservableValue<T?>, ObservableNotifier {
  /// Actual control to subscribe.
  final _parent = ActionControl.empty<T>();

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

  @override
  ObservableValue<U> cast<U>() => this as ObservableValue<U>;

  @override
  void dispose() {
    super.dispose();

    _parent.dispose();
  }
}

mixin NotifierComponent on ControlModel implements ObservableChannel {
  /// Actual control to subscribe.
  final _parent = ControlObservable.empty();

  @override
  ControlSubscription subscribe(VoidCallback action, {dynamic args}) =>
      _parent.subscribe(
        (_) => action.call(),
        current: false,
        args: args,
      );

  @override
  void cancel(ControlSubscription subscription) => _parent.cancel(subscription);

  @override
  void notify() => _parent.notify();

  @override
  void dispose() {
    super.dispose();

    _parent.dispose();
  }
}
