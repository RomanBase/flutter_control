import 'package:flutter_control/core.dart';

class ControlObservable<T> implements Disposable {
  final subs = <ControlSubscription<T>>[];

  bool _active = true;

  T? _value;

  T? get value => _value;

  set value(T? value) => setValue(value);

  bool get isEmpty => value == null;

  bool get isNotEmpty => value != null;

  bool get isValid => true;

  bool get isActive => isValid && _active;

  int get subCount => subs.length;

  ControlSubscription<T> subscribe(
    ValueCallback<T?> action, {
    bool current: true,
  }) {
    final sub = createSubscription();
    subs.add(sub);

    sub.initSubscription(this, action);

    if (current) {
      sub.notifyCallback(value);
    }

    return sub;
  }

  ControlSubscription<T> createSubscription() => ControlSubscription<T>();

  void cancel(ControlSubscription<T> subscription) {
    subscription.invalidate();
    subs.remove(subscription);
  }

  void setValue(T? value, {bool notify: true, bool forceNotify: false}) {
    if (_value == value) {
      if (forceNotify) {
        this.notify();
      }

      return;
    }

    _value = value;

    if (notify || forceNotify) {
      this.notify();
    }
  }

  void pause() => _active = false;

  void resume() => _active = isValid;

  void notify() {
    if (!isActive) {
      return;
    }

    subs.forEach((element) => element.notifyCallback(value));
  }

  @override
  void dispose() {
    subs.forEach((element) => element.invalidate());
    subs.clear();
  }
}
