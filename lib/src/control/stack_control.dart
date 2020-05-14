import 'package:flutter_control/core.dart';

class StackControl<T> implements ActionControlStream, Disposable {
  final _stack = List<T>();

  final _control = ActionControl.broadcast<T>();

  T get _last => _stack.isEmpty ? null : _stack.last;

  List<T> get stack => List<T>.of(_stack);

  @override
  T get value => _control.value;

  bool get canPop => _stack.isNotEmpty;

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

  T pop() {
    if (!canPop) {
      return null;
    }

    final item = _stack.removeLast();

    _notifyControl();

    return item;
  }

  void setStack(Iterable<T> stack) {
    _stack.clear();
    _stack.addAll(stack);

    _notifyControl();
  }

  void clear({bool keepLast: false}) {
    if (!canPop) {
      return;
    }

    if (keepLast) {
      final last = _last;
      _stack.clear();
      _stack.add(last);
    } else {
      _stack.clear();
    }

    _notifyControl();
  }

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
