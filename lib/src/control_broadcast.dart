import 'package:flutter_control/core.dart';

/// Global stream to broadcast data and events.
class ControlBroadcast implements Disposable {
  /// List of active subs.
  final _globalSubscriptions = List<GlobalSubscription>();

  /// Last available value for subs.
  final _globalValue = Map();

  int get subCount => _globalSubscriptions.length;

  /// Subscription to global stream
  GlobalSubscription<T> subscribe<T>(dynamic key, ValueChanged<T> onData) {
    assert(onData != null);

    final sub = GlobalSubscription<T>(key);

    sub._parent = this;
    sub._onData = onData;

    _globalSubscriptions.add(sub);

    final lastValue = _globalValue[sub.key];

    if (lastValue != null && sub.isValidForBroadcast(sub.key, lastValue)) {
      sub._notify(lastValue);
    }

    return sub;
  }

  /// Subscription to global stream
  GlobalSubscription subscribeEvent(dynamic key, VoidCallback callback) {
    return subscribe(key, (_) => callback());
  }

  /// Cancels subscriptions to global stream
  void cancelSubscription(GlobalSubscription sub) {
    sub.pause();
    _globalSubscriptions.remove(sub);
  }

  /// Sets data to global stream.
  /// Subs with same [key] and [value] type will be notified.
  /// [store] - stores value for future subs and notifies them during [subscribe] phase.
  int broadcast(dynamic key, dynamic value, {bool store: false}) {
    int count = 0;

    if (store) {
      _globalValue[key] = value;
    }

    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, value)) {
        count++;
        sub._notify(value);
      }
    });

    return count;
  }

  /// Sets data to global stream.
  /// Subs with same [key] will be notified.
  int broadcastEvent(dynamic key) {
    int count = 0;

    _globalSubscriptions.forEach((sub) {
      if (sub.isValidForBroadcast(key, null)) {
        count++;
        sub._notify(null);
      }
    });

    return count;
  }

  void clear() {
    _globalSubscriptions.forEach((sub) => sub._parent = null);
    _globalSubscriptions.clear();
    _globalValue.clear();
  }

  @override
  void dispose() {
    clear();
  }
}

class GlobalSubscription<T> implements Disposable {
  /// Key of global sub.
  /// [ControlFactory.broadcast]
  final dynamic key;

  /// Parent of this sub - who creates and setup this sub.
  ControlBroadcast _parent;

  /// Callback from sub.
  /// [ControlFactory.broadcast]
  ValueChanged<T> _onData;

  bool _active = true;

  /// Checks if parent is valid and sub is active.
  bool get isActive => _parent != null && _active;

  /// Default constructor.
  GlobalSubscription(this.key);

  /// Checks if [key] and [value] type is eligible for this sub.
  bool isValidForBroadcast(dynamic key, dynamic value) => _active && (value == null || value is T) && (key == null || key == this.key);

  /// Pauses this subscription and [ControlFactory] broadcast will skip this sub.
  void pause() => _active = false;

  /// Resumes this subscription and [ControlFactory] broadcast will again starts notifying this sub.
  void resume() => _active = true;

  void _notify(dynamic value) => _onData(value as T);

  /// Cancels subscription to global stream in [ControlFactory].
  void cancel() {
    _active = false;
    if (_parent != null) {
      _parent.cancelSubscription(this);
    }
  }

  @override
  void dispose() {
    cancel();
    _parent = null;
  }
}