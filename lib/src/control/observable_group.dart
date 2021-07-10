import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

class ObservableGroup implements ObservableModel<Iterable> {
  final _items = <DisposableToken>[];

  final _parent = ActionControl.broadcast<Iterable>();

  @override
  Iterable? get value => _parent.value;

  @override
  set value(Iterable? value) => _parent.value = value;

  int get length => _items.length;

  operator [](int index) => _getValue(_items[index]);

  ObservableGroup([Iterable? observables]) {
    observables?.forEach((item) => join(item));
  }

  dynamic _getValue(DisposableToken? token) {
    if (token == null) {
      return null;
    }

    final item = token.data;

    if (item is ObservableModel) {
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

  Iterable _getValues() => _items.map((item) => _getValue(item));

  /// Supports [ActionControl], [FieldControl] and [Listenable]. Other objects will be passed unchanged.
  DisposableToken join(dynamic observer) {
    final event = DisposableClient(parent: this);

    if (observer is ObservableModel) {
      final sub = observer.subscribe((value) => _notifyControl());
      event.onCancel = sub.dispose;
    } else if (observer is FieldControlStream) {
      // ignore: cancel_subscriptions
      final sub = observer.subscribe((event) => _notifyControl());
      event.onCancel = sub.dispose;
    } else if (observer is Listenable) {
      observer.addListener(_notifyControl);
      event.onCancel = () => observer.removeListener(_notifyControl);
    }

    final token = event.asToken(data: observer);

    event.onDispose = () {
      _items.remove(token);
    };

    _items.add(token);

    return token;
  }

  void cancel(DisposableToken token, {bool dispose: true}) {
    _items.remove(token);

    if (dispose) {
      token.cancel();
    }
  }

  void _notifyControl() => _parent.value = _getValues();

  void notify() => _parent.notify();

  @override
  void dispose() {
    _parent.dispose();
    _items.forEach((item) => item.cancel());
    _items.clear();
  }

  @override
  void setValue(Iterable? value, {bool notify = true, bool forceNotify = false}) => _parent.setValue(
        value ?? [],
        notify: notify,
        forceNotify: forceNotify,
      );

  @override
  ControlSubscription<Iterable> subscribe(ValueCallback<Iterable?> action, {bool current = true, dynamic args}) => _parent.subscribe(
        action,
        current: current,
        args: args,
      );
}
