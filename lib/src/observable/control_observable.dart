import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

class ControlObservable<T> implements Disposable {
  final subs = <ControlSubscription<T>>[];

  dynamic data;

  bool _active = true;

  T? _value;

  T? get value => _value;

  set value(T? value) => setValue(value);

  bool get isEmpty => value == null;

  bool get isNotEmpty => value != null;

  bool get isValid => true;

  bool get isActive => isValid && _active;

  int get subCount => subs.length;

  static ControlObservable<T> of<T>(dynamic object) {
    if (object is ControlObservable<T>) {
      return object;
    } else if (object is Stream<T>) {
      return ofStream(object);
    } else if (object is Future<T>) {
      return ofFuture(object);
    } else if (object is Listenable) {
      return ofListenable(object);
    }

    return ControlObservable<T>()..value = object;
  }

  static ControlObservable<T> ofStream<T>(Stream<T> stream) {
    final observable = _ClientObservable<T>();
    final sub = stream.listen((event) => observable.setValue(event));

    observable.register(DisposableClient()..onDispose = () => sub.cancel());

    return observable;
  }

  static ControlObservable<T> ofFuture<T>(Future<T> future) {
    final observable = ControlObservable<T>();

    future.then((value) => observable.setValue(value)).catchError((err) {
      printDebug(err);
    });

    return observable;
  }

  static ControlObservable<T> ofListenable<T>(Listenable listenable) {
    final observable = _ClientObservable<T>();

    final callback = () {
      if (listenable is ValueListenable<T>) {
        observable.setValue(listenable.value);
      } else {
        observable.notify();
      }
    };

    listenable.addListener(callback);
    observable.register(DisposableClient()
      ..onDispose = () => listenable.removeListener(callback));

    return observable;
  }

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

class _ClientObservable<T> extends ControlObservable<T> {
  Disposable? _disposable;

  void register(Disposable object) {
    _disposable = object;
  }

  @override
  void dispose() {
    _disposable?.dispose();
    _disposable = null;

    super.dispose();
  }
}
