part of '../../core.dart';

/// Strict implementation of [ObservableValue] based on [ControlObservable].
/// [ActionControl.single] - Only one sub can be active.
/// [ActionControl.broadcast] - Multiple subs can be used.
/// [ActionControl.empty] - Null version - one or multiple subs can be used.
/// [ActionControl.provider] - Subscription to global [BroadcastProvider].
class ActionControl<T> extends ControlObservable<T> {
  /// Global subscription.
  BroadcastSubscription<T>? _globalSub;

  bool _single = true;

  ///Default private constructor.
  ActionControl._(super.value);

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  /// Only one sub can be active. Last given [subscribe] is held.
  /// Check [broadcast] or [empty] to support more listeners.
  static ActionControl<T> single<T>(T value) => ActionControl<T>._(value);

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  /// Multiple subs can be used.
  /// Check [single] or [empty] for different approaches.
  static ActionControl<T> broadcast<T>(T value) =>
      ActionControl<T>._(value).._single = false;

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  /// Set [broadcast] to restrict sub count.
  /// Check [ActionControl.single], [ActionControl.broadcast].
  static ActionControl<T?> empty<T>({T? value, bool broadcast = true}) =>
      ActionControl<T?>._(value).._single = !broadcast;

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  static ActionControl<T?> provider<T>(
      {dynamic key, T? defaultValue, bool broadcast = true}) {
    final control = ActionControl<T?>._(defaultValue).._single = !broadcast;

    control._globalSub = BroadcastProvider.subscribe<T>(
      key,
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
