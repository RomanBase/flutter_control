import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

class ObservableGroup implements ActionControlObservable<List>, Disposable {
  final _items = List<DisposableToken>();

  final _control = ActionControl.broadcast<List>();

  @override
  List get value => _control.value;

  List get _values => _items.map((item) {
        if (item is ActionControlObservable) {
          return (item as ActionControlObservable).value;
        }

        if (item is FieldControlStream) {
          return (item as FieldControlStream).value;
        }

        if (item is ValueListenable) {
          return (item as ValueListenable).value;
        }

        return item;
      });

  ObservableGroup([List observables]) {
    observables?.forEach((item) => join(item));
  }

  /// Supports [ActionControl], [FieldControl] and [Listenable].
  DisposableToken join(dynamic observer) {
    final token = DisposableToken(parent: this);
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
  ActionControlListenable<List> get listenable => _control.listenable;

  @override
  ActionSubscription<List> once(ValueCallback<List> action,
          {Predicate<List> until, bool current = true}) =>
      _control.once(action, until: until, current: current);

  @override
  ActionSubscription<List> subscribe(ValueCallback<List> action,
          {bool current = true}) =>
      _control.subscribe(action, current: current);

  /// [ActionControlObservable.equal]
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  @override
  void dispose() {
    _control.dispose();
    _items.forEach((item) => item.cancel());
    _items.clear();
  }
}
