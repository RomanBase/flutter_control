import 'dart:async';

import 'package:flutter_control/core.dart';

mixin ObservableComponent<T> on ControlModel implements ObservableValue<T> {
  /// Actual control to subscribe.
  final _parent = ActionControl.broadcast<T>();

  @override
  dynamic data;

  @override
  T? get value => _parent.value;

  set value(T? value) => _parent.value = value;

  void setValue(T? value, {bool notify: true, bool forceNotify: false}) {
    _parent.setValue(
      value,
      notify: notify,
      forceNotify: forceNotify,
    );
  }

  @override
  ControlSubscription<T> subscribe(ValueCallback<T?> action,
          {bool current: true, dynamic args}) =>
      _parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription<T> subscription) =>
      _parent.cancel(subscription);

  void notify() => _parent.notify();

  @override
  void dispose() {
    super.dispose();

    _parent.dispose();
  }
}

/// @{macro action-control}
///
/// [ActionControl.single] - Only one sub can be active.
/// [ActionControl.broadcast] - Multiple subs can be used.
/// [ActionControl.provider] - Subscription to [BroadcastProvider].
class ActionControl<T> extends ControlObservable<T> {
  /// Global subscription.
  BroadcastSubscription<T>? _globalSub;

  bool get _single => true;

  ///Default constructor.
  ActionControl._([T? value]) : super(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Only one sub can be active.
  static ActionControl<T> single<T>([T? value]) => ActionControl<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Multiple subs can be used.
  static ActionControl<T> broadcast<T>([T? value]) =>
      _ActionControlBroadcast<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  static ActionControl<T> provider<T>({dynamic key, T? defaultValue}) {
    final control = _ActionControlBroadcast<T>._(defaultValue);

    control._globalSub = BroadcastProvider.subscribe<T>(
      Control.factory.keyOf<T>(key: key),
      (data) => control.setValue(data),
    );

    return control;
  }

  @override
  ControlSubscription<T> subscribe(action,
      {bool current = true, dynamic args}) {
    if (_single && subCount > 0) {
      subs.clear();
    }

    return super.subscribe(action, current: current, args: args);
  }

  @override
  void dispose() {
    _globalSub?.dispose();
    _globalSub = null;

    super.dispose();
  }

  @override
  String toString() {
    return value?.toString() ?? 'NULL - ${super.toString()}';
  }
}

/// Broadcast version of [ActionControl]
class _ActionControlBroadcast<T> extends ActionControl<T> {
  @override
  bool get _single => false;

  _ActionControlBroadcast._([T? value]) : super._(value);
}
