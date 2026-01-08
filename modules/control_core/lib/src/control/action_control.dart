part of '../../core.dart';

/// Provides specialized implementations of [ObservableValue] with distinct subscription behaviors.
///
/// Use the factory constructors to create an `ActionControl` with a specific behavior:
/// - [ActionControl.single]: Allows only one subscriber at a time.
/// - [ActionControl.broadcast]: Allows multiple subscribers (default behavior).
/// - [ActionControl.empty]: A nullable version that allows multiple subscribers.
/// - [ActionControl.leaf]: Wraps another observable, bubbling up its notifications.
/// - [ActionControl.provider]: Syncs its value with the global [BroadcastProvider].
class ActionControl<T> extends ControlObservable<T> {
  /// Internal constructor for factory use.
  ActionControl._(super.value);

  /// Creates an [ObservableValue] that allows only a single subscriber.
  ///
  /// When a new subscriber is added, the previous one is automatically removed.
  /// This is useful for cases where a value should only have one active listener.
  static ActionControl<T> single<T>(T value) => _ActionControlSingle<T>(value);

  /// Creates an [ObservableValue] that allows multiple subscribers.
  ///
  /// This is the standard behavior for an observable.
  static ActionControl<T> broadcast<T>(T value) => ActionControl<T>._(value);

  /// Creates a nullable [ObservableValue] that allows multiple subscribers.
  static ActionControl<T?> empty<T>({T? value}) => ActionControl<T?>._(value);

  /// Creates an [ObservableValue] that listens to another observable (`leaf`).
  ///
  /// When the nested `leaf` observable changes, this `ActionControl` will notify
  /// its own listeners, effectively "bubbling up" the notification.
  static ActionControl<T?> leaf<T extends ObservableBase>({T? value}) =>
      _ActionControlLeaf<T>(value);

  /// Creates an [ObservableValue] that syncs with the global [BroadcastProvider].
  ///
  /// It subscribes to the `BroadcastProvider` with the given [key]. When a new value
  /// is broadcasted on that channel, this control's value is updated.
  ///
  /// Conversely, when this control's value is changed via `setValue`, it broadcasts
  /// the new value globally.
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
