part of '../core.dart';

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

class BroadcastSubscriptionArgs<T> {
  final dynamic key;
  final bool nullOk;

  const BroadcastSubscriptionArgs({
    required this.key,
    this.nullOk = true,
  });

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

  /// In most of cases not used directly
  /// Check [subscribeTo] / [subscribeOf] and [subscribeEvent] / [subscribeEventOf]
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

  /// Subscribe to global object stream for given [key] and [Type].
  /// [onData] callback is triggered when [broadcast] with specified [key] and correct [value] is called.
  /// [current] when object for given [key] is stored from previous [broadcast], then [onData] is notified immediately.
  ///
  /// Returns [BroadcastSubscription] to control and close subscription.
  /// Check [subscribeOf] to subscribe with Type [T].
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

  /// Subscribe to global object stream for given [Type]. This [Type] is used as broadcast [key].
  /// [onData] callback is triggered when [broadcast] with specified [key] and correct [value] is called.
  /// [current] when object for given [key] is stored from previous [broadcast], then [onData] is notified immediately.
  ///
  /// Returns [BroadcastSubscription] to control and close subscription.
  /// Check [subscribeTo] to subscribe with custom key.
  BroadcastSubscription<T> subscribeOf<T>(
    ValueChanged<T?> onData, {
    bool current = true,
    bool nullOk = true,
  }) {
    assert(T != dynamic);

    return subscribeTo<T>(T, onData, current: current, nullOk: nullOk);
  }

  /// Subscribe to global event stream for given [key].
  /// [callback] is triggered when [broadcast] or [broadcastEvent] with specified [key] is called.
  ///
  /// Returns [BroadcastSubscription] to control and close subscription.
  /// Check [subscribeEventOf] to subscribe with Type [T].
  BroadcastSubscription subscribeEvent(Object key, VoidCallback callback) {
    return subscribeTo(key, (_) => callback(), current: false);
  }

  /// Subscribe to global event stream for given [Type]. This [Type] is used as broadcast [key].
  /// [callback] is triggered when [broadcast] or [broadcastEvent] with specified [key] is called.
  ///
  /// Returns [BroadcastSubscription] to control and close subscription.
  /// Check [subscribeEvent] to subscribe with custom key.
  BroadcastSubscription subscribeEventOf<T>(VoidCallback callback) {
    assert(T != dynamic);

    return subscribeEvent(T, callback);
  }

  /// Sends [value] to global object stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores [value] for future subs and notifies them immediately after [subscribe].
  ///
  /// Returns number of notified subs.
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

  /// Sends event to global event stream.
  /// Subs with same [key] will be notified.
  ///
  /// Returns number of notified subs.
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

/// Subscription of global data/event stream.
/// Holds subscription [key] and [Type] and callback [onData] event.
class BroadcastSubscription<T> extends ControlSubscription<T> {
  /// Key of sub.
  final dynamic key;

  /// Checks if 'null' is valid for broadcast.
  final bool nullOk;

  /// Default constructor.
  /// Only [ControlBroadcast] can initialize sub.
  BroadcastSubscription._(this.key, {this.nullOk = true});

  /// Checks if [key] and [value] is eligible for this subscription.
  bool isValidForBroadcast(dynamic key, dynamic value) =>
      (key == this.key) && ((value == null && nullOk) || value is T);
}
