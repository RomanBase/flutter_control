part of '../core.dart';

/// Exception thrown when a [BroadcastSubscription] cannot be created.
///
/// This typically happens when a `null` key is provided during subscription,
/// which is not allowed.
class BroadcastSubscriptionException implements Exception {
  dynamic args;

  BroadcastSubscriptionException([this.args]);

  @override
  String toString() {
    if (args == null || args is! BroadcastSubscriptionArgs) {
      return 'No arguments provided - [BroadcastSubscriptionArgs]';
    }

    if (args!.key == null) {
      return 'No broadcast Key provided - [BroadcastSubscriptionArgs]';
    }

    return 'Unable to establish [BroadcastSubscription] with given args: $args';
  }
}

/// Arguments for creating a [BroadcastSubscription].
///
/// This class encapsulates the parameters needed to create a subscription,
/// making it easier to pass them around.
class BroadcastSubscriptionArgs<T> {
  /// The unique key to identify the broadcast stream.
  final dynamic key;

  /// Whether `null` values are considered valid for this subscription.
  /// If `false`, `null` values broadcasted on this channel will be ignored.
  final bool nullOk;

  const BroadcastSubscriptionArgs({
    required this.key,
    this.nullOk = true,
  });

  /// Creates a new [BroadcastSubscription] instance from these arguments.
  BroadcastSubscription<T> createSubscription() =>
      BroadcastSubscription._(key, nullOk: nullOk);
}

/// Global stream to broadcast data and events.
/// Stream is driven by keys and object types.
///
/// Default broadcast is created with [ControlFactory] and is possible to use it via [BroadcastProvider].
class ControlBroadcast implements ObservableNotifier, Disposable {
  final _observable = ControlObservable<dynamic>(null);

  /// Last available value for subs.
  final _store = {};

  /// Actual observable that holds all listeners.
  /// This is exposed just for debug and test purposes.
  /// DO NOT modify directly any fields in release.
  ControlObservable get observable => _observable;

  /// Number of active listeners.
  int get subCount => _observable.subCount;

  /// Checks availability of this broadcast.
  /// Inactive broadcast will not serve any data.
  bool get isActive => _observable.isActive;

  /// Pauses all broadcasting.
  void pause() => _observable.pause();

  /// Resumes broadcast distribution.
  bool resume() => _observable.resume();

  /// Subscribes to the broadcast stream with detailed control.
  ///
  /// This is a low-level method. In most cases, it's more convenient to use
  /// [subscribeTo] for data streams or [subscribeEvent] for event notifications.
  ///
  /// - [action]: The callback to execute when a valid broadcast is received.
  /// - [current]: If `true` and a value is already stored for the given key,
  ///   the [action] is called immediately with the stored value.
  /// - [args]: The [BroadcastSubscriptionArgs] defining the subscription key and behavior.
  ///
  /// Returns a [BroadcastSubscription] that can be used to manage the subscription.
  BroadcastSubscription subscribe(
    ValueCallback action, {
    bool current = true,
    required BroadcastSubscriptionArgs args,
  }) {
    final sub = _createSubscription(args);
    _observable.subs.add(sub);

    sub.initSubscription(_observable, action);

    if (current &&
        _store.containsKey(args.key) &&
        sub.isValidForBroadcast(sub.key, _store[args.key])) {
      sub.notifyCallback(_store[args.key]);
    }

    return sub;
  }

  BroadcastSubscription _createSubscription(BroadcastSubscriptionArgs args) {
    if (args.key == null) {
      throw BroadcastSubscriptionException(args);
    }

    return args.createSubscription();
  }

  /// Subscribes to the object stream for a given [key] and [Type].
  ///
  /// The [onData] callback is triggered when [broadcast] is called with a matching
  /// [key] and a value of type [T].
  ///
  /// - [key]: The key identifying the broadcast channel.
  /// - [onData]: The callback that receives the broadcasted data.
  /// - [current]: If `true`, notifies the subscriber immediately with the last stored value if available.
  /// - [nullOk]: If `false`, `null` values will be ignored for this subscription.
  ///
  /// To subscribe by type only (using the type `T` as the key), see [subscribeOf].
  ///
  /// Returns a [BroadcastSubscription] to manage the subscription.
  BroadcastSubscription<T> subscribeTo<T>(
    Object key,
    ValueChanged<T?> onData, {
    bool current = true,
    bool nullOk = true,
  }) =>
      subscribe(
        (data) => onData.call(data == null ? null : data as T),
        current: current,
        args: BroadcastSubscriptionArgs<T>(
          key: key,
          nullOk: nullOk,
        ),
      ) as BroadcastSubscription<T>;

  /// Subscribes to the object stream using the type [T] as the broadcast key.
  ///
  /// This is a convenience method for `subscribeTo<T>(T, onData)`.
  ///
  /// The [onData] callback is triggered when [broadcast] is called with a value of type [T].
  ///
  /// - [onData]: The callback that receives the broadcasted data.
  /// - [current]: If `true`, notifies the subscriber immediately with the last stored value if available.
  /// - [nullOk]: If `false`, `null` values will be ignored for this subscription.
  ///
  /// Returns a [BroadcastSubscription] to manage the subscription.
  BroadcastSubscription<T> subscribeOf<T>(
    ValueChanged<T?> onData, {
    bool current = true,
    bool nullOk = true,
  }) {
    assert(T != dynamic);

    return subscribeTo<T>(T, onData, current: current, nullOk: nullOk);
  }

  /// Subscribes to an event stream for a given [key].
  ///
  /// This is used for simple notifications without data. The [callback] is triggered
  /// when `broadcastEvent` is called with a matching [key].
  ///
  /// - [key]: The key identifying the event channel.
  /// - [callback]: The function to call when the event is broadcasted.
  ///
  /// To subscribe by type only (using the type `T` as the key), see [subscribeEventOf].
  ///
  /// Returns a [BroadcastSubscription] to manage the subscription.
  BroadcastSubscription subscribeEvent(Object key, VoidCallback callback) {
    return subscribeTo(key, (_) => callback(), current: false);
  }

  /// Subscribes to an event stream using the type [T] as the broadcast key.
  ///
  /// This is a convenience method for `subscribeEvent(T, callback)`.
  ///
  /// The [callback] is triggered when `broadcastEvent<T>()` is called.
  ///
  /// - [callback]: The function to call when the event is broadcasted.
  ///
  /// Returns a [BroadcastSubscription] to manage the subscription.
  BroadcastSubscription subscribeEventOf<T>(VoidCallback callback) {
    assert(T != dynamic);

    return subscribeEvent(T, callback);
  }

  /// Sends a [value] to the object stream, notifying relevant subscribers.
  ///
  /// Subscribers with a matching [key] and a compatible value type [T] will be notified.
  ///
  /// - [key]: The key identifying the broadcast channel. If not provided, it's inferred from [T] or the value's type.
  /// - [value]: The data to broadcast.
  /// - [store]: If `true`, the [value] is stored and will be delivered to any future subscribers
  ///   that subscribe with `current: true`.
  ///
  /// Returns the number of subscribers that were notified.
  int broadcast<T>({
    dynamic key,
    required dynamic value,
    bool store = false,
  }) {
    if (!isActive) {
      printDebug('Broadcast is not active!');
      return 0;
    }

    key = Control.factory.keyOf<T>(key: key, value: value);
    int count = 0;

    if (store) {
      _store[key] = value;
    }

    _observable.subs.cast<BroadcastSubscription>().forEach((sub) {
      if (sub.isValidForBroadcast(key, value)) {
        count++;
        sub.notifyCallback(value);
      }
    });

    return count;
  }

  /// Sends a notification on the event stream, notifying relevant subscribers.
  ///
  /// This is equivalent to calling `broadcast<T>(key: key, value: null)`.
  ///
  /// - [key]: The key identifying the event channel. If not provided, it's inferred from [T].
  ///
  /// Returns the number of subscribers that were notified.
  int broadcastEvent<T>({dynamic key}) => broadcast<T>(key: key, value: null);

  /// Returns stored object by give - exact [key].
  /// Object can be stored during [broadcast].
  T? getStore<T>({Object? key}) {
    key ??= Control.factory.keyOf<T>(key: key);

    if (_store.containsKey(key)) {
      return _store[key] as T?;
    }

    return null;
  }

  /// Invalidates current store.
  /// If [key] is given, then only this will be removed.
  bool invalidateStore({Object? key}) {
    if (key != null) {
      return _store.remove(key);
    }

    _store.clear();
    return true;
  }

  void clear() {
    _store.clear();
    _observable.clear();
  }

  @override
  void notify() {
    for (final entry in _store.entries) {
      broadcast(key: entry.key, value: entry.value);
    }
  }

  @override
  void dispose() {
    clear();
  }
}

/// Represents a subscription to a [ControlBroadcast] stream.
///
/// This class holds the subscription's [key] and [Type] and provides a way to
/// validate incoming broadcasts. It should not be constructed directly; instead,
/// it is returned by the `subscribe` methods of [ControlBroadcast].
///
/// The subscription is automatically managed by the parent `ControlObservable`,
/// but you can call `dispose()` to manually cancel it.
class BroadcastSubscription<T> extends ControlSubscription<T> {
  /// The key that this subscription listens to.
  final dynamic key;

  /// Determines if `null` is a valid value for this subscription.
  /// If `false`, broadcasted `null` values will be ignored.
  final bool nullOk;

  /// Internal constructor. Only [ControlBroadcast] can create a subscription.
  BroadcastSubscription._(this.key, {this.nullOk = true});

  /// Checks if a broadcast with the given [key] and [value] is valid for this subscription.
  ///
  /// A broadcast is valid if:
  /// 1. Its `key` matches this subscription's `key`.
  /// 2. Its `value` is of type `T`, or is `null` if `nullOk` is true.
  bool isValidForBroadcast(dynamic key, dynamic value) =>
      (key == this.key) && ((value == null && nullOk) || value is T);
}
