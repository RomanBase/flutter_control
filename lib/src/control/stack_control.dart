import 'package:flutter_control/core.dart';

class StackControl<T> implements ActionControlStream, Disposable {
  final _stack = List<T>();

  final _control = ActionControl.broadcast<T>();

  T get _last => _stack.isEmpty ? null : _stack.last;

  @override
  T get value => _control.value;

  set value(T value) => push(value);

  bool get canPop => _stack.isNotEmpty;

  int get length => _stack.length;

  operator [](int index) => _stack[index];

  StackControl([T value]) {
    if (value != null) {
      push(value);
    }
  }

  void push(T value) {
    if (this.value == value) {
      return;
    }

    _stack.add(value);
    _notifyControl();
  }

  void pushUnique(T value) {
    _stack.remove(value);
    _stack.add(value);

    _notifyControl();
  }

  void pushStack(Iterable<T> stack, {bool clearOrigin: false}) {
    if (clearOrigin) {
      _stack.clear();
    }

    _stack.addAll(stack);

    _notifyControl();
  }

  void pop() {
    if (!canPop) {
      return;
    }

    _stack.removeLast();

    _notifyControl();
  }

  void popTo(T value) {
    int index = _stack.indexOf(value);

    if (index > -1) {
      _stack.removeRange(index, _stack.length);
    }

    _notifyControl();
  }

  void popUntil(Predicate<T> test) {
    int index = _stack.indexWhere(test);

    if (index > -1) {
      _stack.removeRange(index, _stack.length);
    }

    _notifyControl();
  }

  void popToFirst() {
    if (!canPop) {
      return;
    }

    final item = _stack[0];

    _stack.clear();
    _stack.add(item);

    _notifyControl();
  }

  void popToLast() {
    if (!canPop) {
      return;
    }

    final item = _last;

    _stack.clear();
    _stack.add(item);

    _notifyControl();
  }

  void clear() {
    _stack.clear();

    _notifyControl();
  }

  bool contains(T item) => _stack.contains(item);

  void _notifyControl() => _control.value = _last;

  void notify() => _control.notify();

  void cancel([ActionSubscription sub]) => _control.cancel(sub);

  ActionSubscription<T> subscribe(ValueCallback<T> action, {bool current: true}) => _control.subscribe(action, current: current);

  ActionSubscription<T> once(ValueCallback<T> action, {Predicate<T> until, bool current: true}) => _control.once(action, until: until, current: current);

  @override
  bool operator ==(other) {
    return other is ActionControlStream && other.value == value || other == value;
  }

  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  @override
  int get hashCode => value?.hashCode ?? super.hashCode;

  @override
  void dispose() {
    _stack.clear();
    _control.dispose();
  }
}
