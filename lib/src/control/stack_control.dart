import 'package:flutter_control/core.dart';

class StackControl<T> implements ActionControlStream<T>, Disposable {
  /// Current stack of values.
  final _stack = List<T>();

  /// Holds current value and [ActionControlStream] interface just wraps this control.
  final _control = ActionControl.broadcast<T>();

  /// First value is root. [pop] until first value.
  final bool root;

  /// Last value in stack.
  T get _last => _stack.isEmpty ? null : _stack.last;

  /// Current/Last value of stack.
  @override
  T get value => _control.value;

  /// Push this value to stack.
  set value(T value) => push(value);

  /// Checks if stack contains enough items to pop last one.
  bool get canPop => root ? _stack.length > 1 : _stack.isNotEmpty;

  /// Number of items in stack.
  int get length => _stack.length;

  /// Returns value in stack by index.
  operator [](int index) => _stack[index];

  StackControl({T value, this.root = false}) {
    if (value != null) {
      push(value);
    }
  }

  /// Push given [value] to end of stack.
  void push(T value) {
    if (this.value == value) {
      return;
    }

    _stack.add(value);
    _notifyControl();
  }

  /// Push given [value] to end of stack.
  /// Previous occurrence of [value] is removed from stack.
  void pushUnique(T value) {
    _stack.remove(value);
    _stack.add(value);

    _notifyControl();
  }

  /// Pushes whole [stack].
  /// Set [clearOrigin] to clear previous stack.
  void pushStack(Iterable<T> stack, {bool clearOrigin: false}) {
    if (clearOrigin) {
      _stack.clear();
    }

    _stack.addAll(stack);

    _notifyControl();
  }

  /// Pops last [value] from stack.
  void pop() {
    if (!canPop) {
      return;
    }

    _stack.removeLast();

    _notifyControl();
  }

  /// Pops to given [value]. All next values are removed from stack.
  void popTo(T value) {
    int index = _stack.indexOf(value);

    if (index > -1) {
      _stack.removeRange(index, _stack.length);
    }

    _notifyControl();
  }

  /// Pops to [value] of given [test]. All next values are removed from stack.
  void popUntil(Predicate<T> test) {
    int index = _stack.indexWhere(test);

    if (index > -1) {
      _stack.removeRange(index, _stack.length);
    }

    _notifyControl();
  }

  /// Pops to root/first value of stack. All next values are removed from stack.
  void popToFirst() {
    if (!canPop) {
      return;
    }

    final item = _stack[0];

    _stack.clear();
    _stack.add(item);

    _notifyControl();
  }

  /// Pops to last value of stack. All previous values are removed from stack.
  void popToLast() {
    if (!canPop) {
      return;
    }

    final item = _last;

    _stack.clear();
    _stack.add(item);

    _notifyControl();
  }

  /// Pops until last item in stack.
  /// Returns [true] if there is nothing to pop.
  bool navigateBack() {
    if (canPop) {
      pop();

      return false;
    }

    return true;
  }

  /// Clears all values in stack. Even if [root] is set to true.
  void clear() {
    _stack.clear();

    _notifyControl();
  }

  /// Checks if given [item] is in stack.
  bool contains(T item) => _stack.contains(item);

  /// Sets [value] to control.
  void _notifyControl() => _control.value = _last;

  /// Notifies all listeners with current [value].
  void notify() => _control.notify();

  /// [ActionControlStream.cancel]
  void cancel([ActionSubscription sub]) => _control.cancel(sub);

  /// [ActionControlStream.subscribe]
  ActionSubscription<T> subscribe(ValueCallback<T> action, {bool current: true}) => _control.subscribe(action, current: current);

  /// [ActionControlStream.once]
  ActionSubscription<T> once(ValueCallback<T> action, {Predicate<T> until, bool current: true}) => _control.once(action, until: until, current: current);

  @override
  bool operator ==(other) {
    return other is ActionControlStream && other.value == value || other == value;
  }

  /// [ActionControlStream.equal]
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  @override
  int get hashCode => value?.hashCode ?? super.hashCode;

  @override
  void dispose() {
    _stack.clear();
    _control.dispose();
  }
}
