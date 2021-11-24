import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

abstract class ObservableChannel implements Disposable {
  ControlSubscription subscribe(
    VoidCallback action, {
    dynamic args,
  });

  void cancel(ControlSubscription subscription);

  @override
  void dispose() {}
}

abstract class ObservableValue<T> implements Disposable {
  T get value;

  dynamic data;

  ControlSubscription<T> subscribe(
    ValueCallback<T?> action, {
    bool current: true,
    dynamic args,
  });

  void cancel(ControlSubscription<T> subscription);

  static ObservableValue<T?> of<T>(ObservableModel<T?> observable) =>
      _ObservableHandler<T?>(observable);

  @override
  void dispose() {}
}

abstract class ObservableModel<T> extends ObservableValue<T> {
  bool get isEmpty => value == null;

  bool get isNotEmpty => value != null;

  bool get isValid;

  bool get isActive;

  set value(T value) => setValue(value);

  void setValue(T value, {bool notify: true, bool forceNotify: false});

  void notify();
}

class _ObservableHandler<T> extends ObservableValue<T> {
  final ObservableValue<T> _parent;

  @override
  T get value => _parent.value;

  _ObservableHandler(this._parent);

  @override
  ControlSubscription<T> subscribe(ValueCallback<T?> action,
          {bool current = true, dynamic args}) =>
      _parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription<T> subscription) =>
      _parent.cancel(subscription);
}

class ControlObservable<T> extends ObservableModel<T> {
  @protected
  final subs = <ControlSubscription<T>>[];

  @override
  dynamic data;

  bool _active = true;

  T _value;

  @override
  T get value => _value;

  @override
  bool get isValid => true;

  @override
  bool get isActive => isValid && _active;

  int get subCount => subs.length;

  ControlObservable(this._value);

  static ControlObservable<T?> empty<T>([T? value]) =>
      ControlObservable<T?>(value);

  static ObservableValue<T?> of<T>(dynamic object) {
    if (object is ObservableValue<T>) {
      return object;
    } else if (object is Stream<T>) {
      return ofStream(object);
    } else if (object is Future<T>) {
      return ofFuture(object);
    } else if (object is Listenable) {
      return ofListenable(object);
    }

    return ControlObservable<T?>(object is T ? object : null);
  }

  static ControlObservable<T?> ofStream<T>(Stream<T> stream) {
    final observable = _ClientObservable<T>();
    final sub = stream.listen((event) => observable.setValue(event));

    observable.register(DisposableClient()..onDispose = () => sub.cancel());

    return observable;
  }

  static ControlObservable<T?> ofFuture<T>(Future<T> future) {
    final observable = ControlObservable<T?>(null);

    future.then((value) => observable.setValue(value)).catchError((err) {
      printDebug(err);
    });

    return observable;
  }

  static ControlObservable<T?> ofListenable<T>(Listenable listenable) {
    final observable = _ClientObservable<T>();

    final callback = () {
      if (listenable is ValueListenable<T>) {
        observable.setValue(listenable.value, forceNotify: true);
      } else {
        observable.notify();
      }
    };

    listenable.addListener(callback);
    observable.register(DisposableClient()
      ..onDispose = () => listenable.removeListener(callback));

    return observable;
  }

  @override
  void setValue(T value, {bool notify: true, bool forceNotify: false}) {
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

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action,
      {bool current: true, dynamic args}) {
    final sub = createSubscription();
    subs.add(sub);

    sub.initSubscription(this, action);

    if (current) {
      sub.notifyCallback(value);
    }

    return sub;
  }

  @protected
  ControlSubscription<T> createSubscription([dynamic args]) =>
      ControlSubscription<T>();

  @override
  void cancel(ControlSubscription<T> subscription) {
    subscription.invalidate();
    subs.remove(subscription);
  }

  void pause() => _active = false;

  void resume() => _active = isValid;

  @override
  void notify() {
    if (!isActive) {
      return;
    }

    subs.forEach((element) => element.notifyCallback(value));
  }

  void clear() {
    subs.forEach((element) => element.invalidate());
    subs.clear();
  }

  @override
  void dispose() {
    clear();
  }
}

class _ControlObservableNullable<T> extends ControlObservable<T?> {
  _ControlObservableNullable([T? value]) : super(value);
}

class _ClientObservable<T> extends _ControlObservableNullable<T> {
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
