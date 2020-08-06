import 'package:flutter_control/core.dart';

class StackControl<T> implements ActionControlObservable<T>, Disposable {
  /// Current stack of values.
  final _stack = List<T>();

  /// Holds current value and [ActionControlObservable] interface just wraps this control.
  final _control = ActionControl.broadcast<T>();

  /// Stack with root value.
  bool _root = false;

  /// First value is root. [pop] until first value.
  bool get isRooted => _root;

  /// Last value in stack.
  T get _last => _stack.isEmpty ? null : _stack.last;

  /// First value in stack.
  T get _first => _stack.isEmpty ? null : _stack.first;

  /// Current/Last value of stack.
  @override
  T get value => _control.value;

  /// Pushes this value to stack.
  set value(T value) => push(value);

  /// Root/First value of stack.
  T get root => isRooted ? _first : null;

  /// Pushes this value to stack and set it as root value.
  set root(T value) {
    _root = true;
    pushStack([value], clearOrigin: true);
  }

  /// Checks if stack contains enough items to pop last one.
  bool get canPop => isRooted ? _stack.length > 1 : _stack.isNotEmpty;

  /// Number of items in stack.
  int get length => _stack.length;

  /// Returns value in stack by index.
  operator [](int index) => _stack[index];

  /// Returns [ActionControlSub] to provide read only version of [StackControl].
  ActionControlObservable<T> get sub => ActionControlSub<T>(_control);

  @override
  ActionControlListenable<T> get listenable => ActionControlListenable<T>(_control);

  StackControl({T value, bool root = false}) {
    _root = root;
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

  /// Disables root value. So stack can pop all values.
  void disableRoot() => _root = false;

  /// Clears all values in stack. Even if [isRooted] is set to true.
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

  /// [ActionControlObservable.cancel]
  void cancel([ActionSubscription sub]) => _control.cancel(sub);

  /// [ActionControlObservable.subscribe]
  ActionSubscription<T> subscribe(ValueCallback<T> action, {bool current: true}) => _control.subscribe(action, current: current);

  /// [ActionControlObservable.once]
  ActionSubscription<T> once(ValueCallback<T> action, {Predicate<T> until, bool current: true}) => _control.once(action, until: until, current: current);

  @override
  bool operator ==(other) {
    return other is ActionControlObservable && other.value == value || other == value;
  }

  /// [ActionControlObservable.equal]
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  @override
  int get hashCode => value?.hashCode ?? super.hashCode;

  @override
  void dispose() {
    _stack.clear();
    _control.dispose();
  }
}
