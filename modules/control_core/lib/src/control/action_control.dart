part of '../../core.dart';

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
  ActionControl._(super.value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Only one sub can be active.
  static ActionControl<T> single<T>(T value) => ActionControl<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Multiple subs can be used.
  static ActionControl<T> broadcast<T>(T value) =>
      _ActionControlBroadcast<T>._(value);

  static ActionControl<T?> empty<T>({T? value, bool broadcast = true}) =>
      broadcast
          ? _ActionControlBroadcast<T?>._(value)
          : ActionControl<T?>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  static ActionControl<T?> provider<T>({dynamic key, T? defaultValue}) {
    final control = _ActionControlBroadcast<T?>._(defaultValue);

    control._globalSub = BroadcastProvider.subscribe<T>(
      Control.factory.keyOf<T>(key: key),
      (data) => control.setValue(data),
    );

    return control;
  }

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action,
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

  _ActionControlBroadcast._(T value) : super._(value);
}
