import 'package:flutter_control/core.dart';

/// Global stream to broadcast data and events.
/// Stream is driven by keys and object types.
///
/// Default broadcast is created with [ControlFactory] and is possible to use it via [BroadcastProvider].
class ControlBroadcast implements Disposable {
  /// List of active subs.
  final _subscriptions = List<BroadcastSubscription>();

  /// Last available value for subs.
  final _store = Map();

  /// Number of active subs.
  int get subCount => _subscriptions.length;

  /// Returns stored object by give - exact [key].
  /// Object can be stored during [broadcast].
  T getStore<T>(dynamic key) {
    if (_store.containsKey(key)) {
      return _store[key] as T;
    }

    return null;
  }

  /// Subscribe to global object stream for given [key] and [Type].
  /// [onData] callback is triggered when [broadcast] with specified [key] and correct [value] is called.
  /// [current] when object for given [key] is stored from previous [broadcast], then [onData] is notified immediately.
  /// Returns [BroadcastSubscription] to control and close subscription.
  BroadcastSubscription<T> subscribe<T>(dynamic key, ValueChanged<T> onData, {bool current: true}) {
    assert(onData != null);

    final sub = BroadcastSubscription<T>._(key)
      .._parent = this
      .._onData = onData;

    _subscriptions.add(sub);

    if (current && _store.containsKey(key) != null && sub.isValidForBroadcast(sub.key, _store[key])) {
      sub._notify(_store[key]);
    }

    return sub;
  }

  /// Subscribe to global event stream for given [key].
  /// [callback] is triggered when [broadcast] or [broadcastEvent] with specified [key] is called.
  /// Returns [BroadcastSubscription] to control and close subscription.
  BroadcastSubscription subscribeEvent(dynamic key, VoidCallback callback) {
    return subscribe(key, (_) => callback(), current: false);
  }

  /// Cancels subscriptions to global object/event stream.
  void cancelSubscription(BroadcastSubscription sub) {
    sub.pause();
    _subscriptions.remove(sub);
  }

  /// Sends [value] to global object stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores [value] for future subs and notifies them immediately after [subscribe].
  /// Returns number of notified subs.
  int broadcast(dynamic key, dynamic value, {bool store: false}) {
    int count = 0;

    if (store) {
      _store[key] = value;
    }

    _subscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, value)) {
        count++;
        sub._notify(value);
      }
    });

    return count;
  }

  /// Sends event to global event stream.
  /// Subs with same [key] will be notified.
  /// Returns number of notified subs.
  int broadcastEvent(dynamic key) => broadcast(key, null);

  /// Clears all subs and stored data.
  void clear() {
    _subscriptions.forEach((sub) => sub._parent = null);
    _subscriptions.clear();
    _store.clear();
  }

  @override
  void dispose() {
    clear();
  }
}

/// Subscription of global data/event stream.
/// Holds subscription [key] and [Type] and callback [onData] event.
class BroadcastSubscription<T> implements Disposable {
  /// Key of sub.
  final dynamic key;

  /// Parent of this sub.
  ControlBroadcast _parent;

  /// Callback from sub.
  ValueChanged<T> _onData;

  /// Only active sub is valid for broadcast.
  bool _active = true;

  /// Checks if parent is valid and sub is active.
  bool get isActive => _parent != null && _active;

  /// Default constructor.
  /// Only [ControlBroadcast] can initialize sub.
  BroadcastSubscription._(this.key);

  /// Checks if [key] and [value] is eligible for this subscription.
  bool isValidForBroadcast(dynamic key, dynamic value) => _active && (value == null || value is T) && (key == null || key == this.key);

  /// Pauses this subscription and [ControlBroadcast.broadcast] will skip this sub during next event.
  void pause() => _active = false;

  /// Resumes this subscription and [ControlBroadcast.broadcast] will notify this sub during next event.
  void resume() => _active = true;

  /// Notifies callback.
  void _notify(dynamic value) => _onData(value as T);

  /// Cancels subscription to global stream in [ControlFactory].
  /// After cancel there is no way to resume this sub.
  void cancel() {
    _active = false;
    if (_parent != null) {
      _parent.cancelSubscription(this);
      _parent = null;
    }
  }

  @override
  void dispose() {
    cancel();
  }
}
