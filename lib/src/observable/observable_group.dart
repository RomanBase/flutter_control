import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

class ObservableGroup extends ObservableValue<Iterable?> implements Disposable {
  final _items = <DisposableToken>[];

  final _parent = ActionControl.empty<Iterable>();

  bool get isActive => _parent.isActive;

  bool get isValid => _parent.isValid;

  @override
  Iterable get value => _parent.value ?? [];

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

    if (item is ObservableValue) {
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

    final sub =
        ControlObservable.of(observer).subscribe((value) => _notifyControl());
    event.onCancel = sub.dispose;

    final token = event.asToken(data: observer);

    event.onDispose = () {
      _items.remove(token);
    };

    _items.add(token);

    return token;
  }

  void _notifyControl() => _parent.value = _getValues();

  @override
  ControlSubscription<Iterable?> subscribe(ValueCallback<Iterable?> action,
          {bool current = true, dynamic args}) =>
      _parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription<Iterable?> subscription) =>
      _parent.cancel(subscription);

  @override
  void dispose() {
    _parent.dispose();
    _items.forEach((item) => item.cancel());
    _items.clear();
  }
}
