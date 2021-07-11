import 'package:flutter_control/core.dart';

class StackControl<T> extends ObservableModel<T> {
  /// Current stack of values.
  final List<T?> _stack = <T>[];

  /// Holds current value and [ActionControlObservable] interface just wraps this control.
  final _parent = ActionControl.broadcast<T>();

  @override
  bool get isActive => _parent.isActive;

  @override
  bool get isValid => _parent.isValid;

  /// Current/Last value of stack.
  @override
  T? get value => _parent.value;

  /// Stack with root value.
  bool _root = false;

  /// First value is root. [pop] until first value.
  bool get isRooted => _root;

  /// Last value in stack.
  T? get _last => _stack.isEmpty ? null : _stack.last;

  /// First value in stack.
  T? get _first => _stack.isEmpty ? null : _stack.first;

  /// Root/First value of stack.
  T? get root => isRooted ? _first : null;

  /// Pushes this value to stack and set it as root value.
  set root(T? value) {
    _root = true;
    pushStack([value], clearOrigin: true);
  }

  /// Checks if stack contains enough items to pop last one.
  bool get canPop => isRooted ? _stack.length > 1 : _stack.isNotEmpty;

  /// Number of items in stack.
  int get length => _stack.length;

  /// Returns value in stack by index.
  operator [](int index) => _stack[index];

  StackControl({T? value, bool root = false}) {
    _root = root;
    if (value != null) {
      push(value);
    }
  }

  /// Push given [value] to end of stack.
  void push(T? value) {
    if (this.value == value) {
      return;
    }

    _stack.add(value);
    _notifyParent();
  }

  /// Push given [value] to end of stack.
  /// Previous occurrence of [value] is removed from stack.
  void pushUnique(T value) {
    _stack.remove(value);
    _stack.add(value);

    _notifyParent();
  }

  /// Pushes whole [stack].
  /// Set [clearOrigin] to clear previous stack.
  void pushStack(Iterable<T?> stack, {bool clearOrigin: false}) {
    if (clearOrigin) {
      _stack.clear();
    }

    _stack.addAll(stack);

    _notifyParent();
  }

  /// Pops last [value] from stack.
  void pop() {
    if (!canPop) {
      return;
    }

    _stack.removeLast();

    _notifyParent();
  }

  /// Pops to given [value]. All next values are removed from stack.
  void popTo(T value) {
    int index = _stack.indexOf(value);

    if (index > -1) {
      _stack.removeRange(index, _stack.length);
    }

    _notifyParent();
  }

  /// Pops to [value] of given [test]. All next values are removed from stack.
  void popUntil(Predicate<T?> test) {
    int index = _stack.indexWhere(test);

    if (index > -1) {
      _stack.removeRange(index, _stack.length);
    }

    _notifyParent();
  }

  /// Pops to root/first value of stack. All next values are removed from stack.
  void popToFirst() {
    if (!canPop) {
      return;
    }

    final item = _stack[0];

    _stack.clear();
    _stack.add(item);

    _notifyParent();
  }

  /// Pops to last value of stack. All previous values are removed from stack.
  void popToLast() {
    if (!canPop) {
      return;
    }

    final item = _last;

    _stack.clear();
    _stack.add(item);

    _notifyParent();
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

  /// Disables root value. So stack can pop all values.
  void disableRoot() => _root = false;

  /// Clears all values in stack. Even if [isRooted] is set to true.
  void clear() {
    _stack.clear();

    _notifyParent();
  }

  /// Checks if given [item] is in stack.
  bool contains(T item) => _stack.contains(item);

  /// Sets [value] to parent control.
  void _notifyParent() => _parent.value = _last;

  @override
  void setValue(T? value, {bool notify = true, bool forceNotify = false}) =>
      push(value);

  @override
  void cancel(ControlSubscription<T> subscription) =>
      _parent.cancel(subscription);

  @override
  ControlSubscription<T> subscribe(
    ValueCallback<T?> action, {
    bool current = true,
    args,
  }) =>
      _parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void notify() => _parent.notify();

  @override
  void dispose() {
    _stack.clear();
    _parent.dispose();
  }
}
