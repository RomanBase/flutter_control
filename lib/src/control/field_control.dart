import 'dart:async';
import 'dart:math';

import 'package:flutter_control/core.dart';

class FieldSubscription<T> implements StreamSubscription<T> {
  StreamSubscription<T> _sub;
  FieldControl<T> _control;
  bool cancelOnError = false;

  FieldSubscription(this._control, this._sub);

  bool get isActive => !isPaused && _control.isSubscriptionActive(this);

  @override
  bool get isPaused => _sub.isPaused;

  void _cancelSub() => _control.cancelSubscription(this, dispose: false);

  Function _wrapOnDone(Function handleDone) {
    return () {
      handleDone();
      _cancelSub();
    };
  }

  Function _wrapOnError(Function handleError) {
    return (err) {
      handleError(err);
      if (cancelOnError) {
        cancel();
      }
    };
  }

  @override
  Future<E> asFuture<E>([E futureValue]) {
    return _sub.asFuture(futureValue);
  }

  @override
  Future cancel() {
    _cancelSub();

    return _sub.cancel();
  }

  @override
  void onData(void Function(T data) handleData) {
    _sub.onData(handleData);
  }

  @override
  void onDone(void Function() handleDone) {
    _sub.onDone(_wrapOnDone(handleDone));
  }

  @override
  void onError(Function handleError) {
    _sub.onError(_wrapOnError(handleError));
  }

  @override
  void pause([Future resumeSignal]) {
    _sub.pause(resumeSignal);
  }

  @override
  void resume() {
    _sub.resume();
  }

  void _cancelStreamSub() {
    _sub.cancel();
  }
}

abstract class FieldControlStream<T> {
  Stream<T> get stream => null;

  T get value => null;

  FieldSubscription subscribe(void onData(T event), {Function onError, void onDone(), bool cancelOnError: false, bool current: true});
}

class FieldControlSub<T> implements FieldControlStream<T> {
  final FieldControl<T> _parent;

  FieldControlSub._(this._parent);

  Stream<T> get stream => _parent.stream;

  T get value => _parent.value;

  @override
  FieldSubscription subscribe(void Function(T event) onData, {Function onError, void Function() onDone, bool cancelOnError = false, bool current = true}) {
    return _parent.subscribe(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError, current: current);
  }
}

/// Enclosure and adds functionality to standard [Stream] and [StreamBuilder] flow.
/// Use [FieldBuilder] or basic variants ([StringBuilder], [BoolBuilder], etc.) for easier integration into Widget.
///
/// There is few basic controllers to work with [BoolControl], [StringControl]. etc.
class FieldControl<T> implements FieldControlStream<T>, Disposable {
  /// Current broadcast [StreamController].
  final _stream = StreamController<T>.broadcast();

  /// List of subscribers for later dispose.
  List<FieldSubscription> _subscriptions;

  /// Default sink of this controller.
  /// Use [sinkConverter] to convert input data.
  Sink<T> get sink => FieldSink<T>(this);

  /// Default stream of this control.
  Stream<T> get stream => _stream.stream;

  /// Returns true if current stream is closed.
  bool get isClosed => _stream.isClosed;

  /// Current value.
  T _value;

  /// Returns current value - last in stream.
  T get value => _value;

  set value(value) => setValue(value);

  /// Checks if any value is available.
  bool get hasData => _value != null;

  bool get isEmpty => _value == null;

  bool get isActive => !_stream.isClosed;

  FieldControlSub<T> get sub => FieldControlSub<T>._(this);

  /// Initializes controller and [Stream] with default value.
  FieldControl([T value]) {
    if (value != null) {
      setValue(value);
    }
  }

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is FieldControl && other.value == value || other == value;
  }

  /// Checks if given object is same as this one.
  /// Returns true if objects are same.
  bool equal(FieldControl other) => identityHashCode(this) == identityHashCode(other);

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
  /// [FieldControl.notify]
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

  FieldSubscription _addSub(StreamSubscription subscription, {Function onError, void onDone(), bool cancelOnError: false}) {
    if (_subscriptions == null) {
      _subscriptions = List();
    }

    final sub = FieldSubscription(this, subscription)
      ..onError(onError)
      ..onDone(onDone)
      ..cancelOnError = cancelOnError;

    _subscriptions.add(sub);

    return sub;
  }

  /// Copy last value from given controller and sets it to its own stream.
  void copyValueFrom(FieldControl<T> controller) => setValue(controller.value);

  /// Copy last value to given controller.
  void copyValueTo(FieldControl<T> controller) => controller.setValue(value);

  /// Returns [Sink] with custom [ValueConverter].
  Sink sinkConverter(ValueConverter<T> converter) => FieldSinkConverter(this, converter);

  /// Sets value after [Future] finished.
  Future onFuture(Future future, {ValueConverter converter}) => future.then((value) => setValue(converter == null ? value : converter(value)));

  /// Subscribes this controller to given [Stream].
  /// Controller will subscribe to input stream and will listen for changes and populate this changes into own stream.
  /// Via [ValueConverter] is possible to convert value from input stream type to own stream value.
  /// [StreamSubscription] is automatically closed during dispose phase of [FieldControl].
  FieldSubscription subscribeTo(Stream stream, {Function onError, void onDone(), bool cancelOnError: false, ValueConverter converter}) {
    return _addSub(
      stream.listen(
        (data) {
          setValue(converter != null ? converter(data) : data);
        },
      ),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Subscribes to [Stream] of this controller.
  /// [StreamSubscription] are automatically closed during dispose phase of [FieldControl].
  FieldSubscription subscribe(void onData(T event), {Function onError, void onDone(), bool cancelOnError: false, bool current: true}) {
    // ignore: cancel_subscriptions
    final subscription = _stream.stream.listen(
      onData,
    );

    if (value != null && current) {
      onData(value);
    }

    return _addSub(
      subscription,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Given [control] will subscribe to [Stream] of this [FieldControl].
  /// Whenever value in [Stream] is changed [control] will be notified.
  /// Via [ValueConverter] is possible to convert value from input stream type to own stream value.
  /// [StreamSubscription] is automatically closed during dispose phase of [control].
  /// [subscribeTo]
  FieldSubscription streamTo(FieldControl control, {Function onError, void onDone(), bool cancelOnError: false, ValueConverter converter}) {
    if (value != null && value != control.value) {
      control.setValue(converter != null ? converter(value) : value);
    }

    return control.subscribeTo(
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
        sub._cancelStreamSub();
      }

      _subscriptions = null;
    }
  }

  /// Cancels and removes specific subscription
  void cancelSubscription(FieldSubscription subscription, {bool dispose: true}) {
    if (_subscriptions != null) {
      _subscriptions.remove(subscription);

      if (dispose) {
        subscription._cancelStreamSub();
      }

      if (_subscriptions.isEmpty) {
        _subscriptions = null;
      }
    }
  }

  bool isSubscriptionActive(FieldSubscription subscription) => isActive && _subscriptions.contains(subscription);

  @override
  String toString() {
    return value?.toString();
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
    @required FieldControlStream<T> control,
    @required AsyncWidgetBuilder<T> builder,
  }) : super(
          key: key,
          initialData: control.value,
          stream: control.stream,
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
    @required FieldControlStream<T> control,
    @required ControlWidgetBuilder<T> builder,
    WidgetBuilder noData,
    this.nullOk: false,
  }) : super(
            key: key,
            control: control,
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

/// Subscribes to all given [controls] and notifies about changes. Build is called whenever value in one of [FieldControl] is changed.
class FieldBuilderGroup extends StatefulWidget {
  final List<FieldControlStream> controls;
  final ControlWidgetBuilder builder; //todo: T

  const FieldBuilderGroup({Key key, @required this.controls, @required this.builder}) : super(key: key);

  @override
  _FieldBuilderGroupState createState() => _FieldBuilderGroupState();
}

class _FieldBuilderGroupState extends State<FieldBuilderGroup> {
  List _values;
  final _subs = List<FieldSubscription>();

  List _mapValues() => widget.controls.map((item) => item.value).toList(growable: false);

  @override
  void initState() {
    super.initState();

    _values = _mapValues();

    widget.controls.forEach((controller) => _subs.add(controller.subscribe(
          (data) => setState(() {
            _values = _mapValues();
          }),
          current: false,
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

//########################################################################################
//########################################################################################
//########################################################################################

/// Controller for [List].
/// Expose functionality of standard [List] and notifies [FieldStreamBuilder] about changes.
class ListControl<T> extends FieldControl<List<T>> {
  /// returns number of items in list.
  int get length => value.length;

  /// return true if there is no item.
  @override
  bool get isEmpty => value != null && value.isEmpty;

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

  /// Filters data into given [controller].
  StreamSubscription filterTo(FieldControl controller, {Function onError, void onDone(), bool cancelOnError: false, ValueConverter converter, Predicate<T> filter}) {
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

      if (notify) {
        this.notify();
      }
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

  /// [Iterable.map].
  Iterable<E> map<E>(E f(T item)) => value.map(f);

  /// [Iterable.contains].
  bool contains(Object object) => value.contains(object);

  /// [Iterable.forEach].
  void forEach(void f(T item)) => value.forEach(f);

  /// [Iterable.reduce].
  T reduce(T combine(T value, T element)) => value.reduce(combine);

  /// [Iterable.fold].
  E fold<E>(E initialValue, E combine(E previousValue, T element)) => value.fold(initialValue, combine);

  /// [Iterable.every].
  bool every(bool test(T element)) => value.every(test);

  /// [Iterable.join].
  String join([String separator = ""]) => value.join(separator);

  /// [Iterable.any].
  bool any(bool test(T element)) => value.any(test);

  /// [Iterable.toList].
  List<T> toList({bool growable = true}) => value.toList(growable: growable);

  /// [Iterable.toSet].
  Set<T> toSet() => value.toSet();

  /// [Iterable.take].
  Iterable<T> take(int count) => value.take(count);

  /// [Iterable.takeWhile].
  Iterable<T> takeWhile(bool test(T value)) => value.takeWhile(test);

  /// [Iterable.skip].
  Iterable<T> skip(int count) => value.skip(count);

  /// [Iterable.skipWhile].
  Iterable<T> skipWhile(bool test(T value)) => value.skipWhile(test);

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T firstWhere(Predicate<T> test) => value.firstWhere(test, orElse: () => null);

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T lastWhere(Predicate<T> test) => value.lastWhere(test, orElse: () => null);

  /// [Iterable.where].
  Iterable<T> where(Predicate<T> test) => value.where(test);

  /// [Iterable.indexWhere]
  int indexWhere(Predicate<T> test, [int start = 0]) => value.indexWhere(test, start);

  /// [List.lastIndexWhere].
  int lastIndexWhere(bool test(T element), [int start]) => value.lastIndexWhere(test, start);

  /// [Iterable.indexOf]
  int indexOf(T object) => value.indexOf(object);

  /// [List.lastIndexOf].
  int lastIndexOf(T element, [int start]) => value.lastIndexOf(element, start);

  /// [List.sublist].
  List<T> sublist(int start, [int end]) => value.sublist(start, end);

  /// [List.getRange].
  Iterable<T> getRange(int start, int end) => value.getRange(start, end);

  /// [List.asMap].
  Map<int, T> asMap() => value.asMap();

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
    @required FieldControl<List<T>> control,
    @required ControlWidgetBuilder<List<T>> builder,
    WidgetBuilder noData,
  }) : super(
            key: key,
            control: control,
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

  bool get hasMessage => message != null;

  /// Inner message of LoadingStatus.
  dynamic message;

  LoadingControl([LoadingStatus status = LoadingStatus.done]) : super(status);

  /// Change status of FieldController and sets inner message.
  void setStatus(LoadingStatus status, {dynamic msg}) {
    message = msg;

    setValue(status);
  }

  /// Change status of FieldController to progress and sets inner message.
  void progress({dynamic msg}) => setStatus(LoadingStatus.progress, msg: msg);

  /// Change status of FieldController to done and sets inner message.
  void done({dynamic msg}) => setStatus(LoadingStatus.done, msg: msg);

  /// Change status of FieldController to error and sets inner message.
  void error({dynamic msg}) => setStatus(LoadingStatus.error, msg: msg);

  /// Change status of FieldController to outdated and sets inner message.
  void outdated({dynamic msg}) => setStatus(LoadingStatus.outdated, msg: msg);

  /// Change status of FieldController to unknown and sets inner message.
  void unknown({dynamic msg}) => setStatus(LoadingStatus.unknown, msg: msg);

  void status(bool loading, {dynamic msg}) => loading ? progress(msg: msg) : done(msg: msg);
}

//TODO: refactor
/// Builder for [LoadingControl].
/// [LoadingStatus]
/// [FieldStreamBuilder]
class LoadingStackBuilder extends FieldStreamBuilder<LoadingStatus> {
  final Map<LoadingStatus, Widget> children;

  LoadingStackBuilder({
    Key key,
    @required LoadingControl control,
    @required this.children,
  }) : super(
            key: key,
            control: control,
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

//TODO: refactor
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
    @required LoadingControl control,
    this.progress,
    this.done,
    this.error,
    this.outdated,
    this.unknown,
  }) : super(
          key: key,
          control: control,
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
                    : control.hasMessage
                        ? Center(
                            child: Text(control.message),
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
  @override
  bool get isEmpty => value?.isEmpty ?? true;

  String regex;

  bool get requestValidation => regex != null;

  StringControl([String value]) : super(value);

  StringControl.withRegex({String value, this.regex}) {
    setWithRegex(value);
  }

  @override
  void setValue(String value) {
    if (requestValidation) {
      setWithRegex(value);
    } else {
      super.setValue(value);
    }
  }

  void setWithRegex(String value, {String regex}) {
    regex ??= this.regex;

    if (RegExp(regex).hasMatch(value ?? '')) {
      super.setValue(value);
    } else {
      printDebug('value is not within regex $regex');
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

  bool get requestRange => min + max != 0.0;

  DoubleControl([double value = 0.0]) : super(value);

  DoubleControl.inRange({double value: 0.0, this.min: 0.0, this.max: 1.0, this.clamp: true}) {
    setInRange(value);
  }

  void setValue(double value) {
    if (requestRange) {
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
      } else {
        printDebug('value is not within range $min - $max');
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

  bool get requestRange => min + max != 0;

  bool get atMin => requestRange && value == min;

  bool get atMax => requestRange && value == max;

  IntegerControl([int value = 0]) : super(value);

  IntegerControl.inRange({int value: 0, this.min: 0, this.max: 100, this.clamp: true}) {
    setInRange(value);
  }

  void setValue(int value) {
    if (requestRange) {
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
      } else {
        printDebug('value is not within range $min - $max');
      }
    }
  }
}
