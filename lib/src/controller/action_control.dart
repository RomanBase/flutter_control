import 'dart:async';

import 'package:flutter_control/core.dart';

/// Subscription to [ActionControl]
class ControlSubscription<T> implements Disposable {
  ActionControl<T> _parent;
  ValueCallback<T> _action;

  bool _keep = true;
  bool _active = true;

  /// Checks if parent and action is valid and sub is active.
  bool get isActive => _active && _parent != null && _active != null;

  /// Removes parent and action reference.
  /// Can be called multiple times.
  void _clear() {
    _parent = null;
    _action = null;
  }

  /// Sets subscription to listen just for one more time, then will be canceled by [ActionControl].
  void onceMore() => _keep = false;

  /// Pauses this subscription and [ActionControl] broadcast will skip this sub.
  void pause() => _active = false;

  /// Resumes this subscription and [ActionControl] broadcast will again starts notifying this sub.
  void resume() => _active = true;

  /// Cancels subscription to [ActionControl]
  /// Can be called multiple times
  void cancel() {
    _parent?.cancel(this);

    _clear();
  }

  void softDispose() {
    _parent?.cancel(this);
    _action = null;
  }

  @override
  void dispose() {
    cancel();
  }
}

abstract class ActionControlSub<T> {
  /// Last value passed to subs.
  T get value;

  /// Subscribes event for changes.
  /// Returns [ControlSubscription] for later cancellation.
  /// When current value isn't null, then given listener is notified immediately.
  ControlSubscription<T> subscribe(ValueCallback<T> action);

  /// Subscribes event for just one next change.
  /// Returns [ControlSubscription] for later cancellation.
  /// If [current] is true and [value] isn't null, then given listener is notified immediately.
  ControlSubscription<T> once(ValueCallback<T> action, {bool current: true});
}

class ActionControlSubscriber<T> implements ActionControlSub<T> {
  final ActionControl<T> _control;

  ActionControlSubscriber._(this._control);

  @override
  T get value => _control.value;

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action) => _control.subscribe(action);

  @override
  ControlSubscription<T> once(ValueCallback<T> action, {bool current: true}) => _control.once(action, current: current);
}

/// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
/// [ActionControl.single] - Only one sub can be active.
/// [ActionControl.broadcast] - Multiple subs can be used.
class ActionControl<T> implements ActionControlSub<T>, Disposable {
  /// Current value.
  T _value;

  @override
  T get value => _value;

  bool get isEmpty => _value == null;

  /// Current subscription.
  ControlSubscription<T> _sub;

  /// Global subscription.
  GlobalSubscription<T> _globalSub;

  Object _lock;

  bool get isLocked => _lock != null;

  ActionControlSub<T> get sub => ActionControlSubscriber._(this);

  ///Default constructor.
  ActionControl._([T value]) {
    _value = value;
  }

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is ActionControl && other.value == value || other == value;
  }

  /// Checks if given object is same as this one.
  /// Returns true if objects are same.
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Only one sub can be active.
  factory ActionControl.single([T value]) => ActionControl<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Multiple subs can be used.
  factory ActionControl.broadcast([T value]) => _ActionControlBroadcast<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  factory ActionControl.broadcastListener({@required dynamic key, bool broadcast: false, T defaultValue}) {
    ActionControl control = broadcast ? ActionControl<T>._(defaultValue) : _ActionControlBroadcast<T>._(defaultValue);

    control._globalSub = BroadcastProvider.subscribe<T>(key, (data) => control.setValue(data));

    return control;
  }

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action) {
    _sub = ControlSubscription<T>()
      .._parent = this
      .._action = action;

    if (_value != null) {
      action(_value);
    }

    return _sub;
  }

  @override
  ControlSubscription<T> once(ValueCallback<T> action, {bool current: true}) {
    final sub = ControlSubscription<T>()
      .._parent = this
      .._action = action
      .._keep = false;

    if (_value != null && current) {
      sub._clear();
      action(_value);
    } else {
      _sub = sub;
    }

    return sub;
  }

  /// Sets lock for this control.
  /// Value now can't be changed without proper [key].
  ActionControl lock(Object key) {
    _lock = key;

    return this;
  }

  /// Unlocks this control.
  /// If proper [key] is passed, then no more key is required to change value.
  /// Returns true if control is unlocked.
  bool unlock(Object key) {
    if (_lock == key) {
      _lock = null;
    }

    return !isLocked;
  }

  /// Sets new value and notifies listeners.
  void setValue(T value, {Object key}) {
    if (isLocked && _lock != key) {
      printDebug('This control is locked. You need proper key to change value.');
      return;
    }

    _value = value;

    notify();
  }

  /// Notifies listeners with current value.
  void notify() {
    if (_sub != null && _sub.isActive) {
      _sub._action(value);

      if (!_sub._keep) {
        cancel();
      }
    }
  }

  /// Removes specified sub from listeners.
  /// If no sub is specified then removes all.
  void cancel([ControlSubscription<T> subscription]) {
    if (_sub != null) {
      _sub._clear();
      _sub = null;
    }
  }

  @override
  void dispose() {
    cancel();

    if (_globalSub != null) {
      _globalSub.dispose();
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
  final _list = List<ControlSubscription<T>>();

  _ActionControlBroadcast._([T value]) : super._(value);

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action) {
    final sub = super.subscribe(action);
    _sub = null; // just clear unused sub reference

    _list.add(sub);

    if (_value != null) {
      action(_value);
    }

    return sub;
  }

  @override
  ControlSubscription<T> once(ValueCallback<T> action, {bool current: true}) {
    final sub = super.once(action, current: current);
    _sub = null; // just clear unused sub reference

    if (sub.isActive) {
      _list.add(sub);
    }

    return sub;
  }

  @override
  void notify() {
    _list.forEach((sub) => sub._action(_value));

    final onceList = _list.where((sub) => !sub._keep);

    if (onceList.isNotEmpty) {
      onceList.forEach((sub) => sub._clear());
      _list.removeWhere((sub) => !sub._keep);
    }
  }

  @override
  void cancel([ControlSubscription<T> subscription]) {
    if (subscription == null) {
      _list.forEach((sub) => sub._clear());
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

/// Listen for changes and updates Widget every time when value is changed.
///
/// [ActionControl.single] - single sub.
/// [ActionControl.broadcast] - multiple subs.
/// [ControlWidgetBuilder] - returns Widget based on given value.
class ControlBuilder<T> extends StatefulWidget {
  final ActionControlSub<T> controller;
  final ControlWidgetBuilder<T> builder;

  const ControlBuilder({
    Key key,
    @required this.controller,
    @required this.builder,
  }) : super(key: key);

  @override
  _ControlBuilderState createState() => _ControlBuilderState<T>();

  Widget build(BuildContext context, T value) => builder(context, value);
}

class _ControlBuilderState<T> extends State<ControlBuilder<T>> {
  T _value;

  ControlSubscription _sub;

  @override
  void initState() {
    super.initState();

    _sub = widget.controller.subscribe((value) {
      setState(() {
        _value = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _value);

  @override
  void dispose() {
    super.dispose();

    _sub.cancel();
  }
}

/// Subscribes to all given [controllers] and notifies about changes. Build is called whenever value in one of [ActionControl] is changed.
class ControlBuilderGroup extends StatefulWidget {
  final List<ActionControlSub> controllers;
  final ControlWidgetBuilder<List> builder;

  const ControlBuilderGroup({
    Key key,
    @required this.controllers,
    @required this.builder,
  }) : super(key: key);

  @override
  _ControlBuilderGroupState createState() => _ControlBuilderGroupState();

  Widget build(BuildContext context, List values) => builder(context, values);
}

class _ControlBuilderGroupState extends State<ControlBuilderGroup> {
  List _values;
  final _subs = List<ControlSubscription>();

  List _mapValues() => widget.controllers.map((item) => item.value).toList(growable: false);

  @override
  void initState() {
    super.initState();

    _values = _mapValues();

    widget.controllers.forEach((controller) => _subs.add(controller.subscribe(
          (data) => setState(() {
            _values = _mapValues();
          }),
        )));
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _values);

  @override
  void dispose() {
    super.dispose();

    _subs.forEach((item) => item.dispose());
    _subs.clear();
  }
}

class BroadcastBuilder<T> extends StatefulWidget {
  final ControlWidgetBuilder<T> builder;
  final T defaultValue;

  dynamic get broadcastKey => (key as ValueKey).value;

  BroadcastBuilder({
    @required dynamic key,
    @required this.builder,
    this.defaultValue,
  }) : super(key: ValueKey(key));

  @override
  State<StatefulWidget> createState() => _BroadcastBuilderState<T>();

  Widget build(BuildContext context, T value) => builder(context, value);
}

class _BroadcastBuilderState<T> extends State<BroadcastBuilder<T>> {
  T _value;

  ActionControl controller;
  ControlSubscription _sub;

  @override
  void initState() {
    super.initState();

    controller = ActionControl<T>.broadcastListener(key: widget.broadcastKey, defaultValue: widget.defaultValue);

    _sub = controller.subscribe((value) {
      setState(() {
        _value = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _value);

  @override
  void dispose() {
    super.dispose();

    _sub.cancel();
    controller.dispose();
  }
}
