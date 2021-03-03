import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

/// Subscription to [ActionControl]
class ActionSubscription<T> implements Disposable {
  /// Creator of this sub.
  ActionControl<T>? _parent;

  /// Listeners callback.
  ValueCallback<T>? _action;

  /// Test when this subscription is ready to close.
  Predicate<T>? _until;

  /// Checks if subscription can be used next time.
  bool _keep = true;

  /// Checks if subscription is not paused.
  bool _active = true;

  /// Checks if parent and callback is set.
  bool get isValid => _parent != null && _action != null;

  /// Checks if parent and action is valid and sub is active.
  bool get isActive => _active && isValid;

  /// Sets test [predicate] to check.
  /// This test is executed after each callback.
  /// Returning 'true' will close this subscription.
  void until(Predicate<T> predicate) => _until = predicate;

  /// Sets subscription to listen just for one more time, then will be canceled by [ActionControl].
  void onceMore() => _keep = false;

  /// Pauses this subscription and [ActionControl] will skip this sub.
  void pause() => _active = false;

  /// Resumes this subscription and [ActionControl] will again starts notifying this sub.
  void resume() => _active = true;

  /// Checks if this subscription is ready to be closed.
  bool _readyToClose(T value) => !_keep || (_until?.call(value) ?? false);

  /// Removes parent and action reference.
  /// Can be called multiple times.
  void _clear() {
    _parent = null;
    _action = null;
  }

  /// Cancels subscription to [ActionControl]
  /// Can be called multiple times
  void cancel() {
    _parent?.cancel(this);

    _clear();
  }

  @override
  void dispose() {
    cancel();
  }
}

/// [ValueListenable] version of [ActionControlObservable].
/// Wraps [ActionControl] and provides [Listenable] api.
class ActionControlListenable<T> implements ValueListenable<T?>, Disposable {
  /// Actual control to subscribe.
  final ActionControl<T> _parent;

  /// Checks if parent [FieldControl.isActive] and any callback is registered.
  final _callbacks = Map<VoidCallback, ActionSubscription?>();

  @override
  T? get value => _parent.value;

  /// Wraps [ActionControl] to [Listenable] version.
  ActionControlListenable(this._parent);

  @override
  void addListener(VoidCallback callback) {
    assert(_parent != null);

    _callbacks[callback] = _parent.subscribe((event) => callback());
  }

  @override
  void removeListener(VoidCallback callback) {
    assert(_parent != null);

    _callbacks[callback]?.dispose();
    _callbacks.remove(callback);
  }

  @override
  void dispose() {
    _callbacks.forEach((key, value) => value!.dispose());
  }
}

/// {@template action-control}
/// Simple Observable/Listenable solution based on subscription and listening about [value] changes.
/// Last [value] is always stored.
/// @{endtemplate}
abstract class ActionControlObservable<T> {
  /// Returns current value - last passed action.
  T get value;

  ActionControlListenable<T> get listenable;

  /// Subscribes callback to action changes.
  /// If [current] is 'true' and [value] isn't 'null', then given listener is notified immediately.
  /// [ActionSubscription] is automatically closed during dispose phase of [ActionControl].
  /// Returns [ActionSubscription] for manual cancellation.
  ActionSubscription<T>? subscribe(ValueCallback<T> action,
      {bool current: true});

  /// Subscribes callback to next action change.
  /// If [until] is 'null' [action] will be called just one time, otherwise until test predicate is hit.
  /// If [current] is 'true' and [value] isn't 'null', then given listener is notified immediately.
  /// [ActionSubscription] is automatically closed during dispose phase of [ActionControl].
  /// Returns [ActionSubscription] for manual cancellation.
  ActionSubscription<T> once(ValueCallback<T> action,
      {Predicate<T>? until, bool current: true});

  /// Checks if given object is same as this one.
  /// Returns true if objects are same.
  bool equal(other);
}

mixin ActionComponent<T> on ControlModel implements ActionControlObservable<T?> {
  /// Actual control to subscribe.
  final _parent = ActionControl.broadcast<T>();

  @override
  T? get value => _parent.value;

  set value(T? value) => _parent.value = value;

  void setValue(T value, {bool notify: true, bool forceNotify: false}) {
    _parent.setValue(value, notifyListeners: notify && !forceNotify);

    if (forceNotify) {
      _parent.notify();
    }
  }

  @override
  ActionControlListenable<T> get listenable =>
      ActionControlListenable<T>(_parent);

  @override
  ActionSubscription<T?>? subscribe(ValueCallback<T?> action,
          {bool current: true}) =>
      _parent.subscribe(action, current: current);

  @override
  ActionSubscription<T> once(ValueCallback<T?> action,
          {Predicate<T>? until, bool current: true}) =>
      _parent.once(action, current: current);

  @override
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  void notify() => _parent.notify();

  @override
  void dispose() {
    super.dispose();

    _parent.dispose();
  }
}

/// @{macro action-control}
///
/// [ActionControl.sub]
class ActionControlSub<T> implements ActionControlObservable<T?> {
  /// Actual control to subscribe.
  final ActionControl<T> _parent;

  /// Private constructor used by [ActionControl].
  ActionControlSub(this._parent);

  @override
  T? get value => _parent.value;

  ActionControlListenable<T> get listenable =>
      ActionControlListenable<T>(_parent);

  @override
  ActionSubscription<T?>? subscribe(ValueCallback<T?> action,
          {bool current: true}) =>
      _parent.subscribe(action, current: current);

  @override
  ActionSubscription<T> once(ValueCallback<T?> action,
          {Predicate<T>? until, bool current: true}) =>
      _parent.once(action, current: current);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is ActionControlObservable && other.value == value ||
        other == value;
  }

  @override
  bool equal(other) => identityHashCode(this) == identityHashCode(other);
}

/// @{macro action-control}
///
/// [ActionControl.single] - Only one sub can be active.
/// [ActionControl.broadcast] - Multiple subs can be used.
/// [ActionControl.provider] - Subscription to [BroadcastProvider].
class ActionControl<T> implements ActionControlObservable<T?>, Disposable {
  /// Current value.
  T? _value;

  @override
  T? get value => _value;

  /// Sets [value] and notifies listeners.
  set value(value) => setValue(value);

  /// Checks if [value] is not 'null'.
  bool get isNotEmpty => _value != null;

  /// Checks if [value] is 'null'.
  bool get isEmpty => _value == null;

  /// Current subscription.
  ActionSubscription<T?>? _sub;

  /// Global subscription.
  BroadcastSubscription<T>? _globalSub;

  /// Returns [ActionControlSub] to provide read only version of [ActionControl].
  ActionControlObservable<T?> get sub => ActionControlSub<T>(this);

  ActionControlListenable<T> get listenable => ActionControlListenable<T>(this);

  ///Default constructor.
  ActionControl._([T? value]) {
    _value = value;
  }

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is ActionControlObservable && other.value == value ||
        other == value;
  }

  @override
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Only one sub can be active.
  static ActionControl<T> single<T>([T? value]) => ActionControl<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Multiple subs can be used.
  static ActionControl<T> broadcast<T>([T? value]) =>
      _ActionControlBroadcast<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  static ActionControl<T?> provider<T>(
      {required dynamic key, bool single: true, T? defaultValue}) {
    ActionControl control = single
        ? ActionControl<T>._(defaultValue)
        : _ActionControlBroadcast<T>._(defaultValue);

    control._globalSub =
        BroadcastProvider.subscribe<T>(key, (data) => control.setValue(data));

    return control as ActionControl<T?>;
  }

  @override
  ActionSubscription<T?>? subscribe(ValueCallback<T?> action,
      {bool current: true}) {
    _sub = ActionSubscription<T>()
      .._parent = this
      .._action = action;

    if (current && _value != null) {
      action(_value);
    }

    return _sub;
  }

  @override
  ActionSubscription<T> once(ValueCallback<T?> action,
      {Predicate<T>? until, bool current: true}) {
    final sub = ActionSubscription<T>()
      .._parent = this
      .._action = action
      .._until = until
      .._keep = false;

    if (_value != null && current) {
      sub._clear();
      action(_value);
    } else {
      _sub = sub;
    }

    return sub;
  }

  /// Sets new value and notifies listeners.
  void setValue(T? value, {bool notifyListeners: true}) {
    if (_value == value) {
      return;
    }

    _value = value;

    if (notifyListeners) {
      notify();
    }
  }

  /// Notifies listeners with current value.
  void notify() {
    if (_sub != null && _sub!.isActive) {
      _sub!._action!(value);

      if (_sub!._readyToClose(value)) {
        cancel();
      }
    }
  }

  /// Removes specified sub from listeners.
  /// If no sub is specified then removes all.
  void cancel([ActionSubscription<T>? subscription]) {
    if (_sub != null) {
      _sub!._clear();
      _sub = null;
    }
  }

  @override
  void dispose() {
    cancel();

    if (_globalSub != null) {
      _globalSub!.dispose();
      _globalSub = null;
    }
  }

  @override
  String toString() {
    return value?.toString() ?? 'NULL - ${super.toString()}';
  }
}

/// Broadcast version of [ActionControl]
class _ActionControlBroadcast<T> extends ActionControl<T> {
  final List<ActionSubscription<T?>?> _list = <ActionSubscription<T>?>[];

  _ActionControlBroadcast._([T? value]) : super._(value);

  @override
  ActionSubscription<T?>? subscribe(ValueCallback<T?> action,
      {bool current: true}) {
    final sub = super.subscribe(action);
    _sub = null; // just clear unused sub reference

    _list.add(sub);

    if (current && _value != null) {
      action(_value);
    }

    return sub;
  }

  @override
  ActionSubscription<T> once(ValueCallback<T?> action,
      {Predicate<T>? until, bool current: true}) {
    final ActionSubscription<T> sub = super.once(action, until: until, current: current);
    _sub = null; // just clear unused sub reference

    if (sub.isActive) {
      _list.add(sub);
    }

    return sub;
  }

  @override
  void notify() {
    final onceList = _list.where((sub) {
      sub!._action!(_value);

      if (sub._readyToClose(value)) {
        sub._clear();
        return true;
      }

      return false;
    });

    if (onceList.isNotEmpty) {
      _list.removeWhere((sub) => !sub!.isValid);
    }
  }

  @override
  void cancel([ActionSubscription<T>? subscription]) {
    if (subscription == null) {
      _list.forEach((sub) => sub!._clear());
      _list.clear();
    } else {
      subscription._clear();
      _list.remove(subscription);
    }
  }

  @override
  void dispose() {
    super.dispose();
    cancel();
  }
}

// TODO: move to WIDGET folder in v1.1
/// Builds Widget whenever value in [ActionControl] is changed.
class ActionBuilder<T> extends StatefulWidget {
  /// Control to subscribe.
  final ActionControlObservable<T> control;

  /// Widget builder.
  final ControlWidgetBuilder<T> builder;

  /// Builds Widget every time when data in control are changed.
  /// [control] - required Action controller. [ActionControl] or [ActionControlSub].
  /// [builder] - required Widget builder. Value is passed directly (including 'null' values).
  const ActionBuilder({
    Key? key,
    required this.control,
    required this.builder,
  }) : super(key: key);

  @override
  _ActionBuilderState createState() => _ActionBuilderState<T>();

  Widget build(BuildContext context, T value) => builder(context, value);
}

/// State of [ActionBuilder].
/// Subscribes to provided Action.
class _ActionBuilderState<T> extends ValueState<ActionBuilder<T?>, T?> {
  /// Active sub to [ActionControl].
  ActionSubscription? _sub;

  @override
  void initState() {
    super.initState();

    value = widget.control.value;
    _initSub();
  }

  void _initSub() {
    _sub = widget.control.subscribe(notifyValue, current: false);
  }

  @override
  void didUpdateWidget(ActionBuilder<T?> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.control.equal(oldWidget.control)) {
      _sub!.cancel();
      _initSub();
    }

    if (value != widget.control.value) {
      notifyValue(widget.control.value);
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context, value);

  @override
  void dispose() {
    super.dispose();

    _sub?.cancel();
    _sub = null;
  }
}

// TODO: remove in v1.1
/// Will be removed in v1.1 - use [ControlBuilderGroup] instead.
/// Subscribes to all given [controls] and notifies about changes. Build is called whenever value in one of [ActionControl] is changed.
class ActionBuilderGroup extends StatefulWidget {
  final List<ActionControlObservable> controls;
  final ControlWidgetBuilder<List?> builder;

  /// Multiple action based Widget builder. Listening every [ActionControlObservable] about changes.
  /// [controls] - List of controls to subscribe about value changes. [ActionControl] and [ActionControlSub].
  /// [builder] - Values to builder are passed in same order as [controls] are. Also 'null' values are passed in.
  const ActionBuilderGroup({
    Key? key,
    required this.controls,
    required this.builder,
  }) : super(key: key);

  @override
  _ActionBuilderGroupState createState() => _ActionBuilderGroupState();

  Widget build(BuildContext context, List? values) => builder(context, values);
}

/// State of [ActionBuilderGroup].
/// Subscribes to all provided Actions.
class _ActionBuilderGroupState extends ValueState<ActionBuilderGroup, List> {
  /// All active subs.
  final _subs = <ActionSubscription?>[];

  /// Maps values from controls to List.
  List _mapValues() =>
      widget.controls.map((item) => item.value).toList(growable: false);

  @override
  void initState() {
    super.initState();

    value = _mapValues();
    _initSubs();
  }

  void _initSubs() {
    widget.controls.forEach((control) => _subs.add(control.subscribe(
          (data) => notifyValue(_mapValues()),
          current: false,
        )));
  }

  @override
  void didUpdateWidget(ActionBuilderGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controls != oldWidget.controls) {
      _subs.forEach((item) => item!.dispose());
      _subs.clear();

      _initSubs();
    }

    List initial = value!;
    List current = _mapValues();

    if (initial.length == current.length) {
      for (int i = 0; i < initial.length; i++) {
        if (initial[i] != current[i]) {
          notifyValue(current);
          break;
        }
      }
    } else {
      notifyValue(current);
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context, value);

  @override
  void dispose() {
    super.dispose();

    _subs.forEach((item) => item!.dispose());
    _subs.clear();
  }
}
