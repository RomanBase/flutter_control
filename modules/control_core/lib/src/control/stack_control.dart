part of '../../core.dart';

/// An observable stack that manages a list of values and notifies listeners
/// about changes to the top of the stack.
///
/// `StackControl` is ideal for managing navigation state or any scenario requiring
/// a LIFO (Last-In, First-Out) data structure with reactivity. The `value` of the
/// control always reflects the item at the top of the stack.
class StackControl<T> extends ObservableValue<T?>
    implements ObservableNotifier {
  /// Current stack of values.
  final List<T> _stack = <T>[];

  /// Holds current value and serves as concrete observable.
  final _parent = ControlObservable<T?>(null);

  bool get isActive => _parent.isActive;

  bool get isValid => _parent.isValid;

  /// The current value at the top of the stack.
  @override
  T? get value => _parent.value;

  /// Stack with root value.
  bool _root = false;

  /// Check is stack is rooted, so [pop] will remove items only to first value.
  bool get isRooted => _root;

  /// Last value in stack.
  T? get _last => _stack.isEmpty ? null : _stack.last;

  /// First value in stack.
  T? get _first => _stack.isEmpty ? null : _stack.first;

  /// The root (first) value of the stack if it is rooted.
  T? get root => isRooted ? _first : null;

  /// Sets the root value of the stack.
  /// This clears the stack and pushes the given value as the new root.
  set root(T? value) {
    _root = true;

    if (value == null) {
      clear();
    } else {
      pushStack([value], clearOrigin: true);
    }
  }

  /// Checks if the stack can be popped.
  /// If rooted, it can be popped only if there is more than one item.
  bool get canPop => isRooted ? _stack.length > 1 : _stack.isNotEmpty;

  /// Number of items in stack.
  int get length => _stack.length;

  /// Index of active pointer.
  /// Returns negative value when stack is empty.
  int get pointer => length - 1;

  /// A copy of all values currently in the stack.
  List<T> get values => List.of(_stack, growable: false);

  /// Returns value in stack by index.
  T operator [](int index) => _stack[index];

  /// Creates an observable stack.
  ///
  /// - [value]: An optional initial value to push onto the stack.
  /// - [root]: If `true`, the stack is rooted, preventing it from being popped empty.
  StackControl({T? value, bool root = false}) {
    _root = root;
    if (value != null) {
      push(value);
    }
  }

  /// Pushes a new [value] onto the top of the stack and notifies listeners.
  ///
  /// - [unique]: If `true`, the value is only pushed if it's different from the current top value.
  void push(T value, {bool unique = true}) {
    if (unique && this.value == value) {
      return;
    }

    _stack.add(value);
    _notifyParent();
  }

  /// Pushes a given [value] to the top, ensuring it appears only once in the stack.
  /// If the value already exists, its previous occurrence is removed.
  void pushUnique(T value) {
    _stack.remove(value);
    _stack.add(value);

    _notifyParent();
  }

  /// Pushes an entire [stack] of items.
  ///
  /// - [clearOrigin]: If `true`, clears the existing stack before pushing the new items.
  void pushStack(Iterable<T> stack, {bool clearOrigin = false}) {
    if (clearOrigin) {
      _stack.clear();
    }

    _stack.addAll(stack);

    _notifyParent();
  }

  /// Swaps the value at a given [index] with a new [value].
  void swap(T value, int index) {
    _stack.removeAt(index);
    _stack.insert(index, value);

    _notifyParent();
  }

  /// Moves an existing [value] to a new [index] in the stack.
  void reorder(T value, int index) {
    _stack.reorder(_stack.indexOf(value), index);

    _notifyParent();
  }

  /// Removes the top value from the stack and notifies listeners.
  /// The next item in the stack becomes the new `value`.
  void pop() {
    if (!canPop) {
      return;
    }

    _stack.removeLast();

    _notifyParent();
  }

  /// Pops the stack until the given [value] is at the top.
  /// All items above the target [value] are removed.
  void popTo(T value) {
    int index = _stack.indexOf(value);

    if (index > -1) {
      _stack.removeRange(index + 1, _stack.length);
    }

    _notifyParent();
  }

  /// Pops the stack until an item passes the [test] predicate.
  void popUntil(Predicate<T?> test) {
    int index = _stack.indexWhere(test);

    if (index > -1) {
      _stack.removeRange(index + 1, _stack.length);
    }

    _notifyParent();
  }

  /// Pops all items until only the root/first item remains.
  void popToFirst() {
    if (!canPop) {
      return;
    }

    final item = _stack[0];

    _stack.clear();
    _stack.add(item);

    _notifyParent();
  }

  /// Clears the stack, leaving only the current top item.
  void popToLast() {
    if (!canPop) {
      return;
    }

    final item = _last as T;

    _stack.clear();
    _stack.add(item);

    _notifyParent();
  }

  /// Pops the stack if possible.
  ///
  /// Returns `false` if a pop occurred, `true` if the stack could not be popped.
  bool maybePop() {
    if (canPop) {
      pop();

      return false;
    }

    return true;
  }

  /// Disables the root, allowing the stack to be popped until it is empty.
  void disableRoot() => _root = false;

  /// Enables the root, preventing the stack from being popped beyond the first item.
  void enableRoot() => _root = true;

  /// Checks if given [item] is in stack.
  bool contains(T item) => _stack.contains(item);

  /// Sets [value] to parent control.
  void _notifyParent([bool force = true]) =>
      _parent.setValue(_last, forceNotify: force);

  @override
  void cancel(ControlSubscription<T?> subscription) =>
      _parent.cancel(subscription);

  @override
  ControlSubscription<T?> subscribe(
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

  /// Clears all values in stack, even if rooted.
  void clear() {
    _stack.clear();

    _notifyParent();
  }

  @override
  void dispose() {
    _stack.clear();
    _parent.dispose();
  }
}
