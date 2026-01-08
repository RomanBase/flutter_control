part of '../../core.dart';

/// A class that groups multiple observables into a single `ObservableValue`.
///
/// An `ObservableGroup` listens to all joined observables. When any of them notify,
/// the group notifies its own listeners. The `value` of the group is an `Iterable`
/// containing the current values of all the observables in the group.
///
/// This is useful for reacting to changes in a combination of states.
class ObservableGroup extends ObservableValue<Iterable?>
    implements ObservableNotifier {
  final _items = <DisposableToken>[];

  final _parent = ActionControl.empty<Iterable>();

  bool get isActive => _parent.isActive;

  bool get isValid => _parent.isValid;

  @override
  Iterable get value => _parent.value ?? [];

  /// The number of observables in the group.
  int get length => _items.length;

  /// Accesses the value of an observable in the group by its index.
  operator [](int index) => _getValue(_items[index]);

  /// Creates a group, optionally pre-filled with an initial list of observables.
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

  /// Adds a new observable to the group.
  ///
  /// The group will start listening to the provided [observable] for changes.
  ///
  /// Returns a [DisposableToken] that can be used to remove the observable from the group.
  DisposableToken join(Object observable) {
    final event = DisposableClient(parent: this);

    final sub =
        ControlObservable.of(observable).subscribe((value) => _notifyControl());
    event.onCancel = sub.dispose;

    final token = event.asToken(data: observable);

    event.onDispose = () {
      _items.remove(token);
    };

    _items.add(token);

    return token;
  }

  void _notifyControl() => _parent.value = _getValues();

  @override
  void notify() => _notifyControl();

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
    for (final item in _items) {
      item.cancel();
    }
    _items.clear();
  }
}
