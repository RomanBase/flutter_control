import 'dart:async';
import 'dart:math';

import 'package:flutter_control/core.dart';

typedef ControlWidgetBuilder<T> = Widget Function(BuildContext context, T value);

typedef bool Predicate<T>(T value);

/// Subscription to [ActionController]
class ActionSubscription<T> implements Disposable {
  ActionController<T> _parent;
  Action<T> _action;
  bool keep = true;

  /// Removes parent and action reference.
  /// Can be called multiple times.
  void _clear() {
    _parent = null;
    _action = null;
  }

  /// Cancels subscription to [ActionController]
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

/// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
/// [ActionController.single] - Only one sub can be active.
/// [ActionController.broadcast] - Multiple subs can be used.
class ActionController<T> implements Disposable {
  /// Current value.
  T _value;

  /// Last value passed to subs.
  T get lastValue => _value;

  /// Current subscription.
  ActionSubscription<T> _sub;

  ///Default constructor.
  ActionController._([T value]) {
    _value = value;
  }

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Only one sub can be active.
  factory ActionController.single([T value]) => ActionController<T>._(value);

  /// Simplified version of [Stream] to provide basic and lightweight functionality to notify listeners.
  /// Multiple subs can be used.
  factory ActionController.broadcast([T value]) => _ActionControllerBroadcast<T>(value);

  /// Subscribes event for changes.
  /// Returns [ActionSubscription] for later cancellation.
  /// When current value isn't null, then given listener is notified immediately.
  ActionSubscription<T> subscribe(Action<T> action) {
    _sub = ActionSubscription<T>();
    _sub._parent = this;
    _sub._action = action;

    if (_value != null) {
      action(_value);
    }

    return _sub;
  }

  /// Subscribes event for just one next change.
  /// Returns [ActionSubscription] for later cancellation.
  /// When current value isn't null, then given listener is notified immediately.
  ActionSubscription<T> once(Action<T> action) {
    _sub = ActionSubscription<T>();
    _sub._parent = this;
    _sub._action = action;
    _sub.keep = false;

    if (_value != null) {
      action(_value);
      cancel();
    }

    return _sub;
  }

  /// Sets new value and notifies listeners.
  void notify(T value) {
    _value = value;

    if (_sub != null) {
      _sub._action(value);

      if (!_sub.keep) {
        cancel();
      }
    }
  }

  /// Removes specified sub from listeners.
  /// If no sub is specified then removes all.
  void cancel([ActionSubscription<T> subscription]) {
    _sub?._clear();
    _sub = null;
  }

  @override
  void dispose() {
    cancel();
  }
}

/// Listen for changes and updates Widget every time when value is changed.
///
/// [ActionController.single] - single sub.
/// [ActionController.broadcast] - multiple subs.
/// [ControlWidgetBuilder] - returns Widget based on given value.
class ActionBuilder<T> extends StatefulWidget {
  final ActionController<T> controller;
  final ControlWidgetBuilder<T> builder;

  const ActionBuilder({Key key, @required this.controller, @required this.builder}) : super(key: key);

  @override
  _ActionBuilderState createState() => _ActionBuilderState<T>();
}

class _ActionBuilderState<T> extends State<ActionBuilder> {
  T _value;
  ActionSubscription<T> _sub;

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

//########################################################################################
//########################################################################################
//########################################################################################

/// Broadcast version of [ActionController]
class _ActionControllerBroadcast<T> extends ActionController<T> {
  final _list = List<ActionSubscription<T>>();

  _ActionControllerBroadcast([T value]) : super._(value);

  @override
  ActionSubscription<T> subscribe(Action<T> action) {
    final sub = super.subscribe(action);
    _sub = null; // just clear unused sub reference

    _list.add(sub);

    if (_value != null) {
      action(_value);
    }

    return sub;
  }

  @override
  ActionSubscription<T> once(Action<T> action) {
    final sub = super.subscribe(action);
    sub.keep = false;

    _sub = null; // just clear unused sub reference

    if (_value != null) {
      action(_value);
    } else {
      _list.add(sub);
    }

    return sub;
  }

  @override
  void notify(T value) {
    _value = value;

    _list.forEach((sub) => sub._action(_value));

    final onceList = _list.where((sub) => !sub.keep);

    if (onceList.isNotEmpty) {
      onceList.forEach((sub) => sub._clear());
      _list.removeWhere((sub) => !sub.keep);
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

/// Enclosure and adds functionality to standard [Stream] and [StreamBuilder] flow.
/// Use [FieldBuilder] or basic variants ([FieldStringBuilder], [FieldBoolBuilder], etc.) for easier integration into Widget.
///
/// There is few basic controllers to work with [BoolController], [StringController]. etc.
class FieldController<T> implements Disposable {
  /// Current broadcast [StreamController].
  final _stream = StreamController<T>.broadcast();

  /// List of subscribers for later dispose.
  List<StreamSubscription> _subscriptions;

  /// Default sink of this controller.
  /// Use [sinkConverter] to convert input data.
  Sink<T> get sink => FieldSink<T>(this);

  /// Returns true if current stream is closed.
  bool get isClosed => _stream.isClosed;

  /// Current value.
  T _value;

  /// Returns current value - last in stream.
  T get value => _value;

  /// Initialize controller and [Stream] with default value.
  FieldController([T value]) {
    if (value != null) {
      setValue(value);
    }
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

  /// Copy last value from given controller and sets it to its own stream.
  void copyValueFrom(FieldController<T> controller) {
    setValue(controller.value);
  }

  /// Copy last value to given controller.
  void copyValueTo(FieldController<T> controller) {
    controller.setValue(value);
  }

  /// Returns [Sink] with custom [Converter].
  Sink<dynamic> sinkConverter(Converter<T> converter) => FieldSinkConverter(this, converter);

  /// Subscribes to [Stream] of this controller.
  /// [StreamSubscription] are automatically closed during dispose phase of [FieldController].
  StreamSubscription subscribe(void onData(T event), {Function onError, void onDone(), bool cancelOnError}) {
    final subscription = _stream.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    if (_subscriptions == null) {
      _subscriptions = List();
    }

    _subscriptions.add(subscription);

    onData(value);

    return subscription;
  }

  /// Subscribes this controller to given [Stream].
  /// Controller will subscribe to input stream and will listen for changes and populate this changes into own stream.
  /// Via [Converter] is possible to convert value from input stream type to own stream value.
  /// [StreamSubscription] is automatically closed during dispose phase of [FieldController].
  StreamSubscription subscribeTo(Stream stream, {Function onError, void onDone(), bool cancelOnError, Converter<T> converter}) {
    if (_subscriptions == null) {
      _subscriptions = List();
    }

    final subscription = stream.listen(
      (data) {
        setValue(converter != null ? converter(data) : data);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    _subscriptions.add(subscription);

    return subscription;
  }

  StreamSubscription streamTo(FieldController<T> controller, {Function onError, void onDone(), bool cancelOnError, Converter<T> converter}) {
    controller.setValue(value);

    return controller.subscribeTo(_stream.stream, onError: onError, onDone: onDone, cancelOnError: cancelOnError, converter: converter);
  }

  @override
  void dispose() {
    _stream.close();

    clearSubscriptions();
  }

  /// Manually cancels and clears all subscriptions.
  void clearSubscriptions() {
    if (_subscriptions != null) {
      for (final sub in _subscriptions) {
        sub.cancel();
      }

      _subscriptions = null;
    }
  }

  /// Cancels and removes specific subscription
  void cancelSubscription(StreamSubscription subscription) {
    _subscriptions.remove(subscription);

    subscription.cancel();
  }
}

/// Standard [Sink] for [FieldController].
class FieldSink<T> extends Sink<T> {
  /// Target FieldController - initialized in constructor
  FieldController _target;

  /// Initialize Sink with target controller
  FieldSink(FieldController<T> target) {
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

/// [Sink] with converter for [FieldController]
/// Converts value and then sends it to controller.
class FieldSinkConverter<T> extends FieldSink<dynamic> {
  /// Value Converter - initialized in constructor
  final Converter<T> converter;

  /// Initialize Sink with target controller and value converter.
  FieldSinkConverter(FieldController<T> target, this.converter) : super(target) {
    assert(converter != null);
  }

  @override
  void add(dynamic data) {
    if (_target != null) {
      _target.setValue(converter(data));
    }
  }
}

/// Extends [StreamBuilder] and adds some functionality to be used easily with [FieldController].
/// If no [Widget] is [build] then empty [Container] is returned.
class FieldBuilder<T> extends StreamBuilder<T> {
  FieldBuilder({
    Key key,
    @required FieldController<T> controller,
    @required AsyncWidgetBuilder<T> builder,
  }) : super(
          key: key,
          initialData: controller._value,
          stream: controller._stream.stream,
          builder: builder,
        );

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) {
    Widget widget = super.build(context, currentSummary);

    return widget ?? Container();
  }
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Controller for [List].
/// Expose functionality of standard [List] and notifies [FieldBuilder] about changes.
class ListController<T> extends FieldController<List<T>> {
  /// returns number of items in list.
  int get length => value.length;

  /// return true if there is no item.
  bool get isEmpty => value.isEmpty;

  bool nullable = false;

  /// Default constructor.
  ListController([Iterable<T> items]) {
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

  /// [Iterable.firstWhere].
  T firstWhere(Predicate<T> test) => value.firstWhere(test);

  /// [Iterable.where].
  Iterable<T> where(Predicate<T> test) => value.where(test);

  /// [Iterable.indexWhere]
  int indexWhere(Predicate<T> test, [int start = 0]) => value.indexWhere(test, start);

  /// [Iterable.clear].
  void clear() => setValue(null);

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

  /// Filters data into given [controller].
  StreamSubscription filterTo(FieldController<List<T>> controller, {Function onError, void onDone(), bool cancelOnError, Converter<T> converter, Predicate<T> filter}) {
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
}

/// Builder for [ListController]
/// [FieldController]
/// [FieldBuilder]
class FieldListBuilder<T> extends FieldObjectBuilder<List<T>> {
  FieldListBuilder({
    Key key,
    @required FieldController<List<T>> controller,
    @required ControlWidgetBuilder<List<T>> builder,
    WidgetBuilder noData,
  }) : super(key: key, controller: controller, builder: builder, noData: noData);
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Shortcut for LoadingStatus Controller.
class LoadingController extends FieldController<LoadingStatus> {
  /// Return true if status is done.
  bool get isDone => value == LoadingStatus.done;

  /// Return true if status is progress.
  bool get inProgress => value == LoadingStatus.progress;

  /// Return true if status is error.
  bool get hasError => value == LoadingStatus.error;

  bool get hasMessage => message?.isNotEmpty ?? false;

  /// Inner message of LoadingStatus.
  String message;

  LoadingController([LoadingStatus status = LoadingStatus.done]) : super(status);

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

/// Builder for [LoadingController].
/// [LoadingStatus]
/// [FieldBuilder]
class FieldLoadingBuilder extends FieldBuilder<LoadingStatus> {
  final WidgetBuilder progress;
  final WidgetBuilder done;
  final WidgetBuilder error;
  final WidgetBuilder outdated;
  final WidgetBuilder unknown;

  FieldLoadingBuilder({
    Key key,
    @required LoadingController controller,
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
                    : Column(
                        children: <Widget>[CircularProgressIndicator()],
                      );
              case LoadingStatus.done:
                return done != null ? done(context) : null;
              case LoadingStatus.error:
                return error != null
                    ? error(context)
                    : controller.hasMessage
                        ? Column(
                            children: <Widget>[Text(controller.message)],
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

/// Object builder - checks if [AsyncSnapshot] has data and builds Widget from [builder] or [noData].
/// [FieldController]
/// [FieldBuilder]
class FieldObjectBuilder<T> extends FieldBuilder<T> {
  FieldObjectBuilder({
    Key key,
    @required FieldController<T> controller,
    @required ControlWidgetBuilder<T> builder,
    WidgetBuilder noData,
  }) : super(
            key: key,
            controller: controller,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return builder(context, snapshot.data);
              }

              if (noData != null) {
                return noData != null ? noData(context) : null;
              }
            });
}

/// Boolean controller
/// [FieldController]
/// [FieldBoolBuilder]
class BoolController extends FieldController<bool> {
  bool get isTrue => value;

  bool get isFalse => !value;

  BoolController([bool value = false]) : super(value);

  void toggle() {
    setValue(!value);
  }

  void setTrue() => setValue(true);

  void setFalse() => setValue(false);
}

/// Builder for [BoolController]
/// [FieldController]
/// [FieldObjectBuilder]
class FieldBoolBuilder extends FieldObjectBuilder<bool> {
  FieldBoolBuilder({
    Key key,
    @required FieldController<bool> controller,
    @required ControlWidgetBuilder<bool> builder,
    WidgetBuilder noData,
  }) : super(key: key, controller: controller, builder: builder, noData: noData);
}

/// String controller
/// [FieldController]
/// [FieldBoolBuilder]
class StringController extends FieldController<String> {
  /// [String.isEmpty]
  bool get isEmpty => value?.isEmpty ?? true;

  StringController([String value]) : super(value);
}

/// Builder for [StringController]
/// [FieldController]
/// [FieldObjectBuilder]
class FieldStringBuilder extends FieldObjectBuilder<String> {
  FieldStringBuilder({
    Key key,
    @required FieldController<String> controller,
    @required ControlWidgetBuilder<String> builder,
    WidgetBuilder noData,
  }) : super(key: key, controller: controller, builder: builder, noData: noData);
}

/// Double controller
/// [FieldController]
/// [FieldBoolBuilder]
class DoubleController extends FieldController<double> {
  DoubleController([double value = 0.0]) : super(value);
}

/// Builder for [DoubleController]
/// [FieldController]
/// [FieldObjectBuilder]
class FieldDoubleBuilder extends FieldObjectBuilder<double> {
  FieldDoubleBuilder({
    Key key,
    @required FieldController<double> controller,
    @required ControlWidgetBuilder<double> builder,
    WidgetBuilder noData,
  }) : super(key: key, controller: controller, builder: builder, noData: noData);
}

/// Integer controller
/// [FieldController]
/// [FieldIntegerBuilder]
class IntegerController extends FieldController<int> {
  IntegerController([int value = 0]) : super(value);
}

/// Builder for [IntegerController]
/// [FieldController]
/// [FieldObjectBuilder]
class FieldIntegerBuilder extends FieldObjectBuilder<int> {
  FieldIntegerBuilder({
    Key key,
    @required FieldController<int> controller,
    @required ControlWidgetBuilder<int> builder,
    WidgetBuilder noData,
  }) : super(key: key, controller: controller, builder: builder, noData: noData);
}
