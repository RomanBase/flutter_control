import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

class ObservableGroup implements ActionControlObservable<Iterable>, Disposable {
  final _items = List<DisposableToken>();

  final _control = ActionControl.broadcast<Iterable>();

  @override
  Iterable get value => _control.value;

  Iterable get _values => _items.map((item) => _getValue(item));

  int get length => _items.length;

  operator [](int index) => _getValue(_items[index]);

  ObservableGroup([List observables]) {
    observables?.forEach((item) => join(item));
  }

  dynamic _getValue(DisposableToken token) {
    final item = token.data;

    if (item is ActionControlObservable) {
      return item.value;
    }

    if (item is FieldControlStream) {
      return item.value;
    }

    if (item is ValueListenable) {
      return item.value;
    }

    return item;
  }

  /// Supports [ActionControl], [FieldControl] and [Listenable].
  DisposableToken join(dynamic observer) {
    final token = DisposableToken(parent: this, data: observer);
    token.onDispose = () {
      _items.remove(token);
      token.finish();
    };

    if (observer is ActionControlObservable) {
      final sub = observer.subscribe((value) => _notifyControl());
      token.onCancel = sub.dispose;
    } else if (observer is FieldControlStream) {
      // ignore: cancel_subscriptions
      final sub = observer.subscribe((event) => _notifyControl());
      token.onCancel = sub.dispose;
    } else if (observer is Listenable) {
      observer.addListener(_notifyControl);
      token.onCancel = () => observer.removeListener(_notifyControl);
    }

    _items.add(token);

    return token;
  }

  void cancel(DisposableToken token, {bool dispose: true}) {
    _items.remove(token);

    if (dispose) {
      token.cancel();
    }
  }

  void _notifyControl() => _control.value = _values;

  void notify() => _control.notify();

  @override
  ActionControlListenable<Iterable> get listenable => _control.listenable;

  @override
  ActionSubscription<Iterable> once(ValueCallback<Iterable> action, {Predicate<List> until, bool current = true}) => _control.once(action, until: until, current: current);

  @override
  ActionSubscription<Iterable> subscribe(ValueCallback<Iterable> action, {bool current = true}) => _control.subscribe(action, current: current);

  /// [ActionControlObservable.equal]
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  @override
  void dispose() {
    _control.dispose();
    _items.forEach((item) => item.cancel());
    _items.clear();
  }
}
