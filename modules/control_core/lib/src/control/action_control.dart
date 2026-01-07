part of '../../core.dart';

/// Strict implementation of [ObservableValue] based on [ControlObservable].
/// [ActionControl.single] - Only one sub can be active.
/// [ActionControl.broadcast] - Multiple subs can be used.
/// [ActionControl.empty] - Null version - one or multiple subs can be used.
/// [ActionControl.leaf] - Value bubbles notification to parent.
/// [ActionControl.provider] - Subscription to global [BroadcastProvider].
class ActionControl<T> extends ControlObservable<T> {
  ///Default private constructor.
  ActionControl._(super.value);

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  /// Only one sub can be active. Last given [subscribe] is held.
  static ActionControl<T> single<T>(T value) => _ActionControlSingle<T>(value);

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  /// Multiple subs can be used.
  static ActionControl<T> broadcast<T>(T value) => ActionControl<T>._(value);

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  static ActionControl<T?> empty<T>({T? value}) => ActionControl<T?>._(value);

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  /// Leaf expects another [ObservableValue] as [value]. Change Notification then bubbles upwards - from [value] to this.
  static ActionControl<T?> leaf<T extends ObservableBase>({T? value}) =>
      _ActionControlLeaf<T>(value);

  /// Strict implementation of [ObservableValue] based on [ControlObservable].
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  /// Also when [value] is changed, then [BroadcastProvider] is notified.
  static ActionControl<T?> provider<T>({dynamic key, T? value}) =>
      _ActionControlGlobal<T>(key, value);

  @override
  String toString() {
    return value?.toString() ?? 'NULL - ${super.toString()}';
  }
}

class _ActionControlSingle<T> extends ActionControl<T> {
  _ActionControlSingle(super.value) : super._();

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action,
      {bool current = true, dynamic args}) {
    if (subCount > 0) {
      subs.clear();
    }

    return super.subscribe(action, current: current, args: args);
  }
}

class _ActionControlLeaf<T extends ObservableBase> extends ActionControl<T?> {
  /// Leaf subscription.
  ControlSubscription? _sub;

  _ActionControlLeaf(super.value) : super._();

  @override
  void setValue(T? value, {bool notify = true, bool forceNotify = false}) {
    _sub?.dispose();

    if (value != null) {
      _sub = value.listen(this.notify);
    }

    super.setValue(value, notify: notify, forceNotify: forceNotify);
  }

  @override
  void dispose() {
    _sub?.dispose();

    super.dispose();
  }
}

class _ActionControlGlobal<T> extends ActionControl<T?> {
  /// Global broadcast key (nullable).
  final dynamic key;

  /// Global subscription.
  late final BroadcastSubscription _globalSub;

  _ActionControlGlobal(this.key, super.value) : super._() {
    _globalSub = BroadcastProvider.subscribe<T>(
      key,
      (data) => setGlobalValue(data),
    );
  }

  void setGlobalValue(T? value) => super.setValue(value);

  @override
  void setValue(T? value, {bool notify = true, bool forceNotify = false}) {
    BroadcastProvider.broadcast<T>(key: key, value: value);

    super.setValue(value, notify: notify, forceNotify: forceNotify);
  }

  @override
  void dispose() {
    _globalSub.dispose();

    super.dispose();
  }

  @override
  String toString() {
    return value?.toString() ?? 'NULL - ${super.toString()}';
  }
}
