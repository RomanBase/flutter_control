import 'dart:async';
import 'dart:math';

import 'package:flutter_control/core.dart';

typedef ControlWidgetBuilder<T> = Widget Function(BuildContext context, T value);

typedef bool Predicate<T>(T value);

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

/// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
/// [ActionControl.single] - Only one sub can be active.
/// [ActionControl.broadcast] - Multiple subs can be used.
class ActionControl<T> implements Disposable {
  /// Current value.
  T _value;

  /// Last value passed to subs.
  T get value => _value;

  /// Current subscription.
  ControlSubscription<T> _sub;

  /// Global subscription.
  GlobalSubscription<T> _globalSub;

  ///Default constructor.
  ActionControl._([T value]) {
    _value = value;
  }

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Only one sub can be active.
  factory ActionControl.single([T value]) => ActionControl<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Multiple subs can be used.
  factory ActionControl.broadcast([T value]) => _ActionControlBroadcast<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// This control will subscribe to [BroadcastProvider] with given [key] and will listen to Global Stream.
  /// Defaultly [broadcast] version of [ActionControl] is created.
  factory ActionControl.globalSubscription(String key, {bool single: false}) {
    ActionControl control = single ? ActionControl<T>._() : _ActionControlBroadcast._();

    control._globalSub = BroadcastProvider.subscribe<T>(key, (data) => control.setValue(data));

    return control;
  }

  /// Subscribes event for changes.
  /// Returns [ControlSubscription] for later cancellation.
  /// When current value isn't null, then given listener is notified immediately.
  ControlSubscription<T> subscribe(ValueCallback<T> action) {
    _sub = ControlSubscription<T>();
    _sub._parent = this;
    _sub._action = action;

    if (_value != null) {
      action(_value);
    }

    return _sub;
  }

  /// Subscribes event for just one next change.
  /// Returns [ControlSubscription] for later cancellation.
  /// When current value isn't null, then given listener is notified immediately.
  ControlSubscription<T> once(ValueCallback<T> action) {
    _sub = ControlSubscription<T>();
    _sub._parent = this;
    _sub._action = action;
    _sub._keep = false;

    if (_value != null) {
      action(_value);
      cancel();
    }

    return _sub;
  }

  /// Sets new value and notifies listeners.
  void setValue(T value) {
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
  ControlSubscription<T> once(ValueCallback<T> action) {
    final sub = super.subscribe(action);
    sub._keep = false;

    _sub = null; // just clear unused sub reference

    if (_value != null) {
      action(_value);
    } else {
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
  final ActionControl<T> controller;
  final ControlWidgetBuilder<T> builder;

  const ControlBuilder({Key key, @required this.controller, @required this.builder}) : super(key: key);

  @override
  _ControlBuilderState createState() => _ControlBuilderState<T>();
}

class _ControlBuilderState<T> extends State<ControlBuilder> {
  T _value;
  ControlSubscription<T> _sub;

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
  Widget build(BuildContext context) => widget.builder(context, _value) ?? Container();

  @override
  void dispose() {
    super.dispose();

    _sub.cancel();
  }
}

class ControlBuilderGroup extends StatefulWidget {
  final List<ActionControl> controllers;
  final ControlWidgetBuilder<List<dynamic>> builder;

  const ControlBuilderGroup({Key key, @required this.controllers, @required this.builder}) : super(key: key);

  @override
  _ControlBuilderGroupState createState() => _ControlBuilderGroupState();
}

class _ControlBuilderGroupState extends State<FieldBuilderGroup> {
  List<dynamic> _values;

  @override
  void initState() {
    super.initState();

    _values = widget.controllers.map((item) => item.value).toList(growable: false);

    widget.controllers.forEach((controller) => controller.subscribe((data) => setState(() {
          _values = widget.controllers.map((item) => item.value).toList(growable: false);
        })));
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _values);
  }
}

//########################################################################################
//########################################################################################
//########################################################################################

class FieldSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _sub;
  final FieldControl<T> control;

  FieldSubscription(this.control, this._sub);

  @override
  bool get isPaused => _sub.isPaused;

  @override
  Future<E> asFuture<E>([E futureValue]) {
    return _sub.asFuture(futureValue);
  }

  @override
  Future cancel() {
    control.cancelSubscription(this, dispose: false);

    return _sub.cancel();
  }

  @override
  void onData(void Function(T data) handleData) {
    _sub.onData(handleData);
  }

  @override
  void onDone(void Function() handleDone) {
    _sub.onDone(handleDone);
  }

  @override
  void onError(Function handleError) {
    _sub.onError(handleError);
  }

  @override
  void pause([Future resumeSignal]) {
    _sub.pause(resumeSignal);
  }

  @override
  void resume() {
    _sub.resume();
  }

  void disposeSubscription() {
    _sub.cancel();
  }
}

/// Enclosure and adds functionality to standard [Stream] and [StreamBuilder] flow.
/// Use [FieldStreamBuilder] or basic variants ([StringBuilder], [BoolBuilder], etc.) for easier integration into Widget.
///
/// There is few basic controllers to work with [BoolControl], [StringControl]. etc.
class FieldControl<T> implements Disposable {
  /// Current broadcast [StreamController].
  final _stream = StreamController<T>.broadcast();

  /// List of subscribers for later dispose.
  List<FieldSubscription> _subscriptions;

  /// Default sink of this controller.
  /// Use [sinkConverter] to convert input data.
  Sink<T> get sink => FieldSink<T>(this);

  /// Returns true if current stream is closed.
  bool get isClosed => _stream.isClosed;

  /// Current value.
  T _value;

  /// Returns current value - last in stream.
  T get value => _value;

  /// Checks if any value is available.
  bool get hasData => _value != null;

  /// Initializes controller and [Stream] with default value.
  FieldControl([T value]) {
    if (value != null) {
      setValue(value);
    }
  }

  /// Initializes [FieldControl] and subscribes it to given [stream].
  /// Check [subscribeTo] function for more info.
  factory FieldControl.of(Stream stream, {T initValue, Function onError, void onDone(), bool cancelOnError: false, ValueConverter<T> converter}) {
    final control = FieldControl(initValue);

    control.subscribeTo(
      stream,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
      converter: converter,
    );

    return control;
  }

  /// Sets the value and adds it to the stream.
  /// If given object is same as current value nothing happens.
  /// [notify] [Stream]
  void setValue(T value) {
    if (_value == value) {
      return;
    }

    _value = value;
    notify();
  }

  /// Notifies current [Stream].
  void notify() {
    if (!_stream.isClosed) {
      _stream.add(_value);
    }
  }

  FieldSubscription _addSub(StreamSubscription<T> subscription) {
    if (_subscriptions == null) {
      _subscriptions = List();
    }

    final sub = FieldSubscription<T>(this, subscription);

    _subscriptions.add(sub);

    return sub;
  }

  /// Copy last value from given controller and sets it to its own stream.
  void copyValueFrom(FieldControl<T> controller) => setValue(controller.value);

  /// Copy last value to given controller.
  void copyValueTo(FieldControl<T> controller) => controller.setValue(value);

  /// Returns [Sink] with custom [ValueConverter].
  Sink<dynamic> sinkConverter(ValueConverter<T> converter) => FieldSinkConverter(this, converter);

  /// Sets value after [Future] finished.
  Future ofFuture(Future<T> future) => future.then((value) => setValue(value));

  /// Subscribes to [Stream] of this controller.
  /// [StreamSubscription] are automatically closed during dispose phase of [FieldControl].
  FieldSubscription subscribe(void onData(T event), {Function onError, void onDone(), bool cancelOnError: false, bool notifyNow: true}) {
    // ignore: cancel_subscriptions
    final subscription = _stream.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    if (value != null && notifyNow) {
      onData(value);
    }

    return _addSub(subscription);
  }

  /// Subscribes this controller to given [Stream].
  /// Controller will subscribe to input stream and will listen for changes and populate this changes into own stream.
  /// Via [ValueConverter] is possible to convert value from input stream type to own stream value.
  /// [StreamSubscription] is automatically closed during dispose phase of [FieldControl].
  FieldSubscription subscribeTo(Stream stream, {Function onError, void onDone(), bool cancelOnError: false, ValueConverter<T> converter}) {
    // ignore: cancel_subscriptions
    final subscription = stream.listen(
      (data) {
        setValue(converter != null ? converter(data) : data);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    return _addSub(subscription);
  }

  /// Given [controller] will subscribe to [Stream] of this [FieldControl].
  /// Whenever value in [Stream] is changed [controller] will be notified.
  /// Via [ValueConverter] is possible to convert value from input stream type to own stream value.
  /// [StreamSubscription] is automatically closed during dispose phase of [controller].
  /// [subscribeTo]
  FieldSubscription streamTo(FieldControl<T> controller, {Function onError, void onDone(), bool cancelOnError: false, ValueConverter<T> converter}) {
    controller.setValue(converter != null ? converter(value) : value);

    return controller.subscribeTo(
      _stream.stream,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
      converter: converter,
    );
  }

  /// Clears subscribers, but didn't close Stream entirely.
  void softDispose() {
    _clearSubscriptions();
  }

  @override
  void dispose() {
    _stream.close();

    _clearSubscriptions();
  }

  /// Manually cancels and clears all subscriptions.
  void _clearSubscriptions() {
    if (_subscriptions != null) {
      for (final sub in _subscriptions) {
        sub.disposeSubscription();
      }

      _subscriptions = null;
    }
  }

  /// Cancels and removes specific subscription
  void cancelSubscription(FieldSubscription subscription, {bool dispose: true}) {
    if (_subscriptions != null) {
      _subscriptions.remove(subscription);

      if (dispose) {
        subscription.disposeSubscription();
      }

      if (_subscriptions.isEmpty) {
        _subscriptions = null;
      }
    }
  }
}

/// Standard [Sink] for [FieldControl].
class FieldSink<T> extends Sink<T> {
  /// Target FieldController - initialized in constructor
  FieldControl _target;

  /// Initialize Sink with target controller
  FieldSink(FieldControl<T> target) {
    assert(target != null);

    _target = target;
  }

  @override
  void add(T data) {
    if (_target != null) {
      _target.setValue(data);
    }
  }

  @override
  void close() {
    _target = null;
  }
}

/// [Sink] with converter for [FieldControl]
/// Converts value and then sends it to controller.
class FieldSinkConverter<T> extends FieldSink<dynamic> {
  /// Value Converter - initialized in constructor
  final ValueConverter<T> converter;

  /// Initialize Sink with target controller and value converter.
  FieldSinkConverter(FieldControl<T> target, this.converter) : super(target) {
    assert(converter != null);
  }

  @override
  void add(dynamic data) {
    if (_target != null) {
      _target.setValue(converter(data));
    }
  }
}

/// Extends [StreamBuilder] and adds some functionality to be used easily with [FieldControl].
/// If no [Widget] is [build] then empty [Container] is returned.
class FieldStreamBuilder<T> extends StreamBuilder<T> {
  FieldStreamBuilder({
    Key key,
    @required FieldControl<T> controller,
    @required AsyncWidgetBuilder<T> builder,
  }) : super(
          key: key,
          initialData: controller._value,
          stream: controller._stream.stream,
          builder: builder,
        );

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) {
    return super.build(context, currentSummary) ?? Container();
  }
}

/// Object builder - checks if [AsyncSnapshot] has data and builds Widget from [builder] or [noData] otherwise.
/// [FieldControl]
/// [FieldStreamBuilder]
class FieldBuilder<T> extends FieldStreamBuilder<T> {
  final bool nullOk;

  FieldBuilder({
    Key key,
    @required FieldControl<T> controller,
    @required ControlWidgetBuilder<T> builder,
    WidgetBuilder noData,
    this.nullOk: false,
  }) : super(
            key: key,
            controller: controller,
            builder: (context, snapshot) {
              if (snapshot.hasData || nullOk) {
                return builder(context, snapshot.data);
              }

              if (noData != null) {
                return noData(context);
              }

              return null;
            });
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Controller for [List].
/// Expose functionality of standard [List] and notifies [FieldStreamBuilder] about changes.
class ListControl<T> extends FieldControl<List<T>> {
  /// returns number of items in list.
  int get length => value.length;

  /// return true if there is no item.
  bool get isEmpty => value.isEmpty;

  bool nullable = false;

  /// Default constructor.
  ListControl([Iterable<T> items]) {
    final list = List<T>();
    if (items != null) {
      list.addAll(items);
    }

    super.setValue(list);
  }

  /// Returns the object at given index.
  T operator [](int index) => value[index];

  @override
  void notify() {
    if (_stream.isClosed) {
      return;
    }

    if (nullable && isEmpty) {
      _stream.add(null);
    } else {
      _stream.add(_value);
    }
  }

  @override
  void setValue(Iterable<T> items) {
    value.clear();

    if (items != null) {
      value.addAll(items);
    }

    notify();
  }

  /// Adds item to List and notifies stream.
  void add(T item) {
    value.add(item);

    notify();
  }

  /// Adds all items to List and notifies stream.
  void addAll(Iterable<T> items) {
    value.addAll(items);

    notify();
  }

  /// Adds item to List at given index and notifies stream.
  void insert(int index, T item) {
    value.insert(index, item);

    notify();
  }

  /// Replaces first item in List for given [test]
  bool replace(T item, Predicate<T> test, [bool notify = true]) {
    final index = value.indexWhere(test);

    final replace = index >= 0;

    if (replace) {
      value.removeAt(index);
      value.insert(index, item);
    }

    if (notify) {
      this.notify();
    }

    return replace;
  }

  /// For every item is performed replace
  void replaceAll(Iterable<T> items, Predicate<T> test) {
    items.forEach((item) => replace(item, test, false));

    notify();
  }

  /// Removes item from List and notifies stream.
  bool remove(T item) {
    final removed = value.remove(item);

    notify();

    return removed;
  }

  /// Removes item from List at given index and notifies stream.
  T removeAt(int index) {
    final item = value.removeAt(index);

    notify();

    return item;
  }

  /// [Iterable.removeWhere].
  void removeWhere(Predicate<T> test) {
    value.removeWhere(test);
    notify();
  }

  /// [List.firstWhere].
  T firstWhere(Predicate<T> test) => value.firstWhere(test);

  /// [List.where].
  Iterable<T> where(Predicate<T> test) => value.where(test);

  /// [Iterable.indexWhere]
  int indexWhere(Predicate<T> test, [int start = 0]) => value.indexWhere(test, start);

  /// [Iterable.indexOf]
  int indexOf(T object) => value.indexOf(object);

  /// [Iterable.clear].
  void clear({bool disposeItems: false}) {
    if (disposeItems) {
      value.forEach((item) {
        if (item is Disposable) {
          item.dispose();
        }
      });
    }

    setValue(null);
  }

  /// [Iterable.sort].
  void sort([int compare(T a, T b)]) {
    value.sort(compare);
    notify();
  }

  /// [Iterable.shuffle].
  void shuffle([Random random]) {
    value.shuffle(random);
    notify();
  }

  /// [List.sublist].
  List<T> sublist(int start, [int end]) => value.sublist(start, end);

  /// Filters data into given [controller].
  StreamSubscription filterTo(FieldControl<List<T>> controller, {Function onError, void onDone(), bool cancelOnError: false, ValueConverter<T> converter, Predicate<T> filter}) {
    return subscribe(
      (data) {
        if (filter != null) {
          data = data.where(filter).toList();
        }

        controller.setValue(converter != null ? converter(data) : data);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void dispose() {
    super.dispose();

    _value.clear();
  }
}

/// Builder for [ListControl]
/// [FieldControl]
/// [FieldStreamBuilder]
class ListBuilder<T> extends FieldStreamBuilder<List<T>> {
  ListBuilder({
    Key key,
    @required FieldControl<List<T>> controller,
    @required ControlWidgetBuilder<List<T>> builder,
    WidgetBuilder noData,
  }) : super(
            key: key,
            controller: controller,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data.length > 0) {
                return builder(context, snapshot.data);
              }

              if (noData != null) {
                return noData(context);
              }

              return null;
            });
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Shortcut for LoadingStatus Controller.
class LoadingControl extends FieldControl<LoadingStatus> {
  /// Return true if status is done.
  bool get isDone => value == LoadingStatus.done;

  /// Return true if status is progress.
  bool get inProgress => value == LoadingStatus.progress;

  /// Return true if status is error.
  bool get hasError => value == LoadingStatus.error;

  bool get hasMessage => message?.isNotEmpty ?? false;

  /// Inner message of LoadingStatus.
  String message;

  LoadingControl([LoadingStatus status = LoadingStatus.done]) : super(status);

  /// Change status of FieldController and sets inner message.
  void setStatus(LoadingStatus status, {String msg}) {
    if (msg != null) {
      message = msg;
    }
    setValue(status);
  }

  /// Change status of FieldController to progress and sets inner message.
  void progress({String msg}) => setStatus(LoadingStatus.progress, msg: msg);

  /// Change status of FieldController to done and sets inner message.
  void done({String msg}) => setStatus(LoadingStatus.done, msg: msg);

  /// Change status of FieldController to error and sets inner message.
  void error({String msg}) => setStatus(LoadingStatus.error, msg: msg);

  /// Change status of FieldController to outdated and sets inner message.
  void outdated({String msg}) => setStatus(LoadingStatus.outdated, msg: msg);

  /// Change status of FieldController to unknown and sets inner message.
  void unknown({String msg}) => setStatus(LoadingStatus.unknown, msg: msg);
}

/// Builder for [LoadingControl].
/// [LoadingStatus]
/// [FieldStreamBuilder]
class LoadingStackBuilder extends FieldStreamBuilder<LoadingStatus> {
  final Map<LoadingStatus, Widget> children;

  LoadingStackBuilder({
    Key key,
    @required LoadingControl controller,
    @required this.children,
  }) : super(
            key: key,
            controller: controller,
            builder: (context, snapshot) {
              if (children == null || children.length == 0) {
                return null;
              }

              final state = snapshot.hasData ? snapshot.data : LoadingStatus.none;

              int index = 0;

              if (children.containsKey(state)) {
                index = children.keys.toList(growable: false).indexOf(state);
              }

              return IndexedStack(
                index: index,
                children: children.values.toList(growable: false),
              );
            });
}

/// Builder for [LoadingControl].
/// [LoadingStatus]
/// [FieldStreamBuilder]
class LoadingBuilder extends FieldStreamBuilder<LoadingStatus> {
  final WidgetBuilder progress;
  final WidgetBuilder done;
  final WidgetBuilder error;
  final WidgetBuilder outdated;
  final WidgetBuilder unknown;

  LoadingBuilder({
    Key key,
    @required LoadingControl controller,
    this.progress,
    this.done,
    this.error,
    this.outdated,
    this.unknown,
  }) : super(
          key: key,
          controller: controller,
          builder: (context, snapshot) {
            final state = snapshot.hasData ? snapshot.data : LoadingStatus.none;

            switch (state) {
              case LoadingStatus.progress:
                return progress != null
                    ? progress(context)
                    : Center(
                        child: CircularProgressIndicator(),
                      );
              case LoadingStatus.done:
                return done != null ? done(context) : null;
              case LoadingStatus.error:
                return error != null
                    ? error(context)
                    : controller.hasMessage
                        ? Center(
                            child: Text(controller.message),
                          )
                        : null;
              case LoadingStatus.outdated:
                return outdated != null ? outdated(context) : null;
              default:
                return unknown != null ? unknown(context) : null;
            }
          },
        );
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Boolean controller
/// [FieldControl]
/// [FieldBuilder]
class BoolControl extends FieldControl<bool> {
  bool get isTrue => value;

  bool get isFalse => !value;

  BoolControl([bool value = false]) : super(value);

  void toggle() {
    setValue(!value);
  }

  void setTrue() => setValue(true);

  void setFalse() => setValue(false);
}

/// String controller
/// [FieldControl]
/// [FieldBuilder]
class StringControl extends FieldControl<String> {
  /// [String.isEmpty]
  bool get isEmpty => value?.isEmpty ?? true;

  String regex;

  bool get validRegex => regex != null;

  StringControl([String value]) : super(value);

  StringControl.withRegex({String value, this.regex}) {
    setWithRegex(value);
  }

  @override
  void setValue(String value) {
    if (validRegex) {
      setWithRegex(value);
    } else {
      super.setValue(value);
    }
  }

  void setWithRegex(String value, {String regex}) {
    regex ??= this.regex;

    if (RegExp(regex).hasMatch(value ?? '')) {
      super.setValue(value);
    }
  }
}

/// Double controller
/// [FieldControl]
/// [FieldBuilder]
class DoubleControl extends FieldControl<double> {
  double min = 0.0;
  double max = 0.0;
  bool clamp = true;

  bool get validRange => min + max != 0.0;

  DoubleControl([double value = 0.0]) : super(value);

  DoubleControl.inRange({double value: 0.0, this.min: 0.0, this.max: 1.0, this.clamp: true}) {
    setInRange(value);
  }

  void setValue(double value) {
    if (validRange) {
      setInRange(value);
    } else {
      super.setValue(value);
    }
  }

  void setInRange(double value, {double min, double max}) {
    if (clamp) {
      super.setValue((value ?? 0).clamp(min ?? this.min, max ?? this.max));
    } else {
      if (value >= min && value <= max) {
        super.setValue(value);
      }
    }
  }
}

/// Integer controller
/// [FieldControl]
/// [FieldBuilder]
class IntegerControl extends FieldControl<int> {
  int min = 0;
  int max = 0;
  bool clamp = true;

  bool get validRange => min + max != 0;

  IntegerControl([int value = 0]) : super(value);

  IntegerControl.inRange({int value: 0, this.min: 0, this.max: 100, this.clamp}) {
    setInRange(value);
  }

  void setValue(int value) {
    if (validRange) {
      setInRange(value);
    } else {
      super.setValue(value);
    }
  }

  void setInRange(int value, {int min, int max}) {
    if (clamp) {
      super.setValue((value ?? 0).clamp(min ?? this.min, max ?? this.max));
    } else {
      if (value >= min && value <= max) {
        super.setValue(value);
      }
    }
  }
}

//########################################################################################
//########################################################################################
//########################################################################################

class FieldBuilderGroup extends StatefulWidget {
  final List<FieldControl> controllers;
  final ControlWidgetBuilder<List<dynamic>> builder;

  const FieldBuilderGroup({Key key, @required this.controllers, @required this.builder}) : super(key: key);

  @override
  _FieldBuilderGroupState createState() => _FieldBuilderGroupState();
}

class _FieldBuilderGroupState extends State<FieldBuilderGroup> {
  List<dynamic> _values;
  final _subs = List<FieldSubscription>();

  List<dynamic> mapValues() => widget.controllers.map((item) => item.value).toList(growable: false);

  @override
  void initState() {
    super.initState();

    _values = mapValues();

    widget.controllers.forEach((controller) => _subs.add(controller.subscribe(
          (data) => setState(() {
            _values = mapValues();
          }),
          notifyNow: false,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _values);
  }

  @override
  void dispose() {
    super.dispose();

    _subs.forEach((sub) => sub.cancel());
    _subs.clear();
  }
}
