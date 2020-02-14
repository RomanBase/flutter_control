import 'dart:async';

import 'package:flutter_control/core.dart';

/// Subscription to [ActionControl]
class ActionSubscription<T> implements Disposable {
  ActionControl<T> _parent;
  ValueCallback<T> _action;
  Predicate<T> _until;

  bool _keep = true;
  bool _active = true;

  bool get isValid => _parent != null && _action != null;

  /// Checks if parent and action is valid and sub is active.
  bool get isActive => _active && isValid;

  /// Removes parent and action reference.
  /// Can be called multiple times.
  void _clear() {
    _parent = null;
    _action = null;
  }

  void until(Predicate<T> predicate) => _until = predicate;

  /// Sets subscription to listen just for one more time, then will be canceled by [ActionControl].
  void onceMore() => _keep = false;

  /// Pauses this subscription and [ActionControl] broadcast will skip this sub.
  void pause() => _active = false;

  /// Resumes this subscription and [ActionControl] broadcast will again starts notifying this sub.
  void resume() => _active = true;

  bool _readyToClose(T value) => _until == null ? !_keep : _until(value);

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

abstract class ActionControlStream<T> {
  /// Last value passed to subs.
  T get value;

  /// Subscribes event for changes.
  /// Returns [ActionSubscription] for later cancellation.
  /// When current value isn't null, then given listener is notified immediately.
  ActionSubscription<T> subscribe(ValueCallback<T> action, {bool current: true});

  /// Subscribes event for just one next change.
  /// Returns [ActionSubscription] for later cancellation.
  /// If [current] is true and [value] isn't null, then given listener is notified immediately.
  ActionSubscription<T> once(ValueCallback<T> action, {Predicate<T> until, bool current: true});

  /// Checks if given object is same as this one.
  /// Returns true if objects are same.
  bool equal(other);
}

class ActionControlSub<T> implements ActionControlStream<T> {
  final ActionControl<T> _control;

  ActionControlSub._(this._control);

  @override
  T get value => _control.value;

  @override
  ActionSubscription<T> subscribe(ValueCallback<T> action, {bool current: true}) => _control.subscribe(action, current: current);

  @override
  ActionSubscription<T> once(ValueCallback<T> action, {Predicate<T> until, bool current: true}) => _control.once(action, current: current);


  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is ActionControlStream && other.value == value || other == value;
  }

  /// Checks if given object is same as this one.
  /// Returns true if objects are same.
  bool equal(other) => identityHashCode(this) == identityHashCode(other);
}

/// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
/// [ActionControl.single] - Only one sub can be active.
/// [ActionControl.broadcast] - Multiple subs can be used.
/// [ActionControl.asBroadcastProvider] - Subscription to [BroadcastProvider].
class ActionControl<T> implements ActionControlStream<T>, Disposable {
  /// Current value.
  T _value;

  @override
  T get value => _value;

  set value(value) => setValue(value);

  bool get isEmpty => _value == null;

  /// Current subscription.
  ActionSubscription<T> _sub;

  /// Global subscription.
  BroadcastSubscription<T> _globalSub;

  ActionControlStream<T> get sub => ActionControlSub<T>._(this);

  ///Default constructor.
  ActionControl._([T value]) {
    _value = value;
  }

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is ActionControlStream && other.value == value || other == value;
  }

  /// Checks if given object is same as this one.
  /// Returns true if objects are same.
  bool equal(other) => identityHashCode(this) == identityHashCode(other);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Only one sub can be active.
  static ActionControl<T> single<T>([T value]) => ActionControl<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Multiple subs can be used.
  static ActionControl<T> broadcast<T>([T value]) => _ActionControlBroadcast<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  //TODO: Do we need this ??!!
  static ActionControl<T> asBroadcastProvider<T>({@required dynamic key, bool single: true, T defaultValue}) {
    ActionControl control = single ? ActionControl<T>._(defaultValue) : _ActionControlBroadcast<T>._(defaultValue);

    control._globalSub = BroadcastProvider.subscribe<T>(key, (data) => control.setValue(data));

    return control;
  }

  @override
  ActionSubscription<T> subscribe(ValueCallback<T> action, {bool current: true}) {
    _sub = ActionSubscription<T>()
      .._parent = this
      .._action = action;

    if (current && _value != null) {
      action(_value);
    }

    return _sub;
  }

  @override
  ActionSubscription<T> once(ValueCallback<T> action, {Predicate<T> until, bool current: true}) {
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
  void setValue(T value, {bool notifyListeners: true}) {

    if (_value == value) {
      return;
    }

    _value = value;

    if(notifyListeners) {
      notify();
    }
  }

  /// Notifies listeners with current value.
  void notify() {
    if (_sub != null && _sub.isActive) {
      _sub._action(value);

      if (_sub._readyToClose(value)) {
        cancel();
      }
    }
  }

  /// Removes specified sub from listeners.
  /// If no sub is specified then removes all.
  void cancel([ActionSubscription<T> subscription]) {
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
  final _list = List<ActionSubscription<T>>();

  _ActionControlBroadcast._([T value]) : super._(value);

  @override
  ActionSubscription<T> subscribe(ValueCallback<T> action, {bool current: true}) {
    final sub = super.subscribe(action);
    _sub = null; // just clear unused sub reference

    _list.add(sub);

    if (current && _value != null) {
      action(_value);
    }

    return sub;
  }

  @override
  ActionSubscription<T> once(ValueCallback<T> action, {Predicate<T> until, bool current: true}) {
    final sub = super.once(action, until: until, current: current);
    _sub = null; // just clear unused sub reference

    if (sub.isActive) {
      _list.add(sub);
    }

    return sub;
  }

  @override
  void notify() {
    final onceList = _list.where((sub) {
      sub._action(_value);

      if (sub._readyToClose(value)) {
        sub._clear();
        return true;
      }

      return false;
    });

    if (onceList.isNotEmpty) {
      _list.removeWhere((sub) => !sub.isValid);
    }
  }

  @override
  void cancel([ActionSubscription<T> subscription]) {
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
class ActionBuilder<T> extends StatefulWidget {
  final ActionControlStream<T> control;
  final ControlWidgetBuilder<T> builder;

  const ActionBuilder({
    Key key,
    @required this.control,
    @required this.builder,
  }) : super(key: key);

  @override
  _ActionBuilderState createState() => _ActionBuilderState<T>();

  Widget build(BuildContext context, T value) => builder(context, value);
}

class _ActionBuilderState<T> extends State<ActionBuilder<T>> {
  T _value;

  ActionSubscription _sub;

  @override
  void initState() {
    super.initState();

    _value = widget.control.value;
    _initSub();
  }

  void _initSub() {
    _sub = widget.control.subscribe(
      (value) {
        setState(() {
          _value = value;
        });
      },
      current: false,
    );
  }

  @override
  void didUpdateWidget(ActionBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.control.equal(oldWidget.control)) {
      _sub.cancel();
      _initSub();
    }

    if (_value != widget.control.value) {
      setState(() {
        _value = widget.control.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _value);

  @override
  void dispose() {
    super.dispose();

    _sub?.cancel();
    _sub = null;
  }
}

/// Subscribes to all given [controls] and notifies about changes. Build is called whenever value in one of [ActionControl] is changed.
class ActionBuilderGroup extends StatefulWidget {
  final List<ActionControlStream> controls;
  final ControlWidgetBuilder<List> builder;

  const ActionBuilderGroup({
    Key key,
    @required this.controls,
    @required this.builder,
  }) : super(key: key);

  @override
  _ActionBuilderGroupState createState() => _ActionBuilderGroupState();

  Widget build(BuildContext context, List values) => builder(context, values);
}

class _ActionBuilderGroupState extends State<ActionBuilderGroup> {
  List _values;
  final _subs = List<ActionSubscription>();

  List _mapValues() => widget.controls.map((item) => item.value).toList(growable: false);

  @override
  void initState() {
    super.initState();

    _values = _mapValues();
    _initSubs();
  }

  void _initSubs() {
    widget.controls.forEach((control) => _subs.add(control.subscribe(
          (data) => setState(() {
            _values = _mapValues();
          }),
          current: false,
        )));
  }

  @override
  void didUpdateWidget(ActionBuilderGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controls != oldWidget.controls) {
      _subs.forEach((item) => item.dispose());
      _subs.clear();

      _initSubs();
    }

    //TODO: check values
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

//TODO: Do we need this ??!!
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

  ActionControl _control;

  @override
  void initState() {
    super.initState();

    _control = ActionControl.asBroadcastProvider<T>(key: widget.broadcastKey, defaultValue: widget.defaultValue);
    _value = _control.value;

    _control.subscribe((value) {
      setState(() {
        _value = value;
      });
    }, current: false);
  }

  @override
  void didUpdateWidget(BroadcastBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    //TODO: check key
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _value);

  @override
  void dispose() {
    super.dispose();

    _control.dispose();
  }
}
