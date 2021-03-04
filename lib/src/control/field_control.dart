import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

class FieldSubscription<T> implements StreamSubscription<T>, Disposable {
  StreamSubscription<T> _sub;
  FieldControl<T> _control;
  bool cancelOnError = false;

  FieldSubscription(this._control, this._sub);

  bool get isActive => !isPaused && _control.isSubscriptionValid(this);

  @override
  bool get isPaused => _sub.isPaused;

  void _cancelSub() => _control.cancelSubscription(this, dispose: false);

  Function _wrapOnDone(Function? handleDone) {
    return () {
      if (handleDone != null) {
        handleDone();
      }

      _cancelSub();
    };
  }

  Function _wrapOnError(Function? handleError) {
    return (err) {
      if (handleError != null) {
        handleError(err);
      }

      if (cancelOnError) {
        cancel();
      }
    };
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return _sub.asFuture(futureValue);
  }

  @override
  Future cancel() {
    _cancelSub();

    return _sub.cancel();
  }

  @override
  void onData(void Function(T data)? handleData) {
    _sub.onData(handleData);
  }

  @override
  void onDone(void Function()? handleDone) {
    _sub.onDone(_wrapOnDone(handleDone) as void Function()?);
  }

  @override
  void onError(Function? handleError) {
    _sub.onError(_wrapOnError(handleError));
  }

  @override
  void pause([Future? resumeSignal]) {
    _sub.pause(resumeSignal);
  }

  @override
  void resume() {
    _sub.resume();
  }

  void _cancelStreamSub() {
    _sub.cancel();
  }

  @override
  void dispose() {
    cancel();
  }
}

/// [ValueListenable] version of [FieldControlStream].
/// Wraps [FieldControl] and provides [Listenable] api.
class FieldControlListenable<T> implements ValueListenable<T?>, Disposable {
  /// Actual control to subscribe.
  FieldControl<T>? _parent;

  /// Map of active callbacks and their subscriptions.
  final _callbacks = Map<VoidCallback, FieldSubscription>();

  /// Checks if parent [FieldControl.isActive] and any callback is registered.
  bool get isActive => _parent!.isActive && _callbacks.isNotEmpty;

  @override
  T? get value => _parent!.value;

  /// Wraps [FieldControl] to [Listenable] version.
  FieldControlListenable(this._parent);

  @override
  void addListener(VoidCallback callback) {
    _callbacks[callback] = _parent!.subscribe((event) => callback());
  }

  @override
  void removeListener(VoidCallback callback) {
    _callbacks[callback]?.dispose();
    _callbacks.remove(callback);
  }

  @override
  void dispose() {
    _parent = null;
    _callbacks.forEach((key, value) => value.dispose());
  }
}

//TODO: check all possible abstract functions from FieldControl.
/// {@template action-control}
/// Async broadcast [Stream] solution based on subscription and listening about [value] changes.
/// Last [value] is always stored.
/// @{endtemplate}
abstract class FieldControlStream<T> {
  /// The [Stream] that this Field wrapping.
  Stream<T> get stream;

  /// Current value - last passed object to [Stream].
  T get value;

  /// Dynamic metadata of this control.
  dynamic get data;

  /// [Listenable] version of this Field.
  FieldControlListenable get listenable;

  /// Subscribes callback to [Stream] changes.
  /// If [current] is 'true' and [value] isn't 'null', then given listener is notified immediately.
  /// [FieldSubscription] is automatically closed during dispose phase of [FieldControl].
  /// Returns [FieldSubscription] for manual cancellation.
  FieldSubscription subscribe(void onData(T event),
      {Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      bool current: true});

  /// Given [control] will subscribe to [Stream] of this Field.
  /// Whenever value in [Stream] is changed [control] will be notified.
  /// Via [ValueConverter] is possible to convert value from input stream type to own stream value.
  /// [StreamSubscription] is automatically closed during dispose phase of [control].
  /// Returns [FieldSubscription] for manual cancellation.
  FieldSubscription streamTo(FieldControl control,
      {Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      ValueConverter? converter});

  bool equal(FieldControlStream other);
}

/// {@macro action-control}
///
/// [FieldControl.sub]
class FieldControlSub<T> implements FieldControlStream<T?> {
  /// Actual control to subscribe.
  final FieldControl<T> _parent;

  /// Wraps [FieldControl] and creates read-only version.
  FieldControlSub(this._parent);

  @override
  Stream<T?> get stream => _parent.stream;

  @override
  T? get value => _parent.value;

  @override
  dynamic get data => _parent.data;

  @override
  FieldControlListenable get listenable => FieldControlListenable<T>(_parent);

  @override
  FieldSubscription subscribe(void Function(T? event) onData,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false,
      bool current = true}) {
    return _parent.subscribe(onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
        current: current);
  }

  @override
  FieldSubscription streamTo(FieldControl control,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false,
      converter}) {
    return _parent.streamTo(control,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
        converter: converter);
  }

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is FieldControlStream && other.value == value ||
        other == value;
  }

  bool equal(FieldControlStream other) =>
      identityHashCode(this) == identityHashCode(other);
}

/// {@macro action-control}
class FieldControl<T> implements FieldControlStream<T?>, Disposable {
  /// Current broadcast [StreamController].
  final StreamController<T?> _stream = StreamController<T>.broadcast();

  /// List of subscribers for later dispose.
  List<FieldSubscription>? _subscriptions;

  /// Default sink of this controller.
  /// Use [sinkConverter] to convert input data.
  Sink<T> get sink => FieldSink<T>(this);

  @override
  Stream<T?> get stream => _stream.stream;

  /// Checks if [Stream] is not closed.
  bool get isActive => !_stream.isClosed;

  /// Returns true if current stream is closed.
  bool get isClosed => _stream.isClosed;

  /// Current value.
  T? _value;

  @override
  T? get value => _value;

  /// Sets value to [Stream] and notifies listeners.
  set value(T? value) => setValue(value);

  /// Checks if [value] is not 'null'.
  bool get isNotEmpty => _value != null;

  /// Checks if [value] is 'null'.
  bool get isEmpty => _value == null;

  @override
  dynamic data;

  /// Returns [FieldControlSub] to provide read only version of [FieldControl].
  FieldControlSub<T> get sub => FieldControlSub<T>(this);

  @override
  FieldControlListenable get listenable => FieldControlListenable<T>(this);

  /// Initializes control and [Stream] with default [value].
  FieldControl([T? value]) {
    if (value != null) {
      setValue(value);
    }
  }

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is FieldControlStream && other.value == value ||
        other == value;
  }

  /// Checks if given object is same as this one.
  /// Returns true if objects are same.
  @override
  bool equal(FieldControlStream other) =>
      identityHashCode(this) == identityHashCode(other);

  /// Initializes [FieldControl] and subscribes it to given [stream].
  /// Check [subscribeTo] function for more info.
  factory FieldControl.of(Stream stream,
      {T? initValue,
      Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      ValueConverter<T>? converter}) {
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

  /// Sets the [value] and adds it to the [Stream].
  /// If given object is same as current value nothing happens.
  /// Set [notifyListeners] to 'false' to prevent notify listeners. Use [FieldControl.notify] to notify listeners manually.
  void setValue(T? value, {bool notifyListeners: true}) {
    if (_value == value) {
      return;
    }

    _value = value;

    if (notifyListeners) {
      notify();
    }
  }

  /// Notifies current [Stream].
  void notify() {
    if (!_stream.isClosed) {
      _stream.add(_value);
    }
  }

  /// Returns [Sink] with custom [ValueConverter].
  Sink sinkConverter(ValueConverter<T> converter) =>
      FieldSinkConverter(this, converter);

  /// Creates sub and stores reference for later dispose..
  FieldSubscription _addSub(StreamSubscription subscription,
      {Function? onError, void onDone()?, bool cancelOnError: false}) {
    if (_subscriptions == null) {
      _subscriptions = [];
    }

    final sub = FieldSubscription(this, subscription)
      ..onError(onError)
      ..onDone(onDone)
      ..cancelOnError = cancelOnError;

    _subscriptions!.add(sub);

    return sub;
  }

  /// Sets [value] after [future] finishes.
  /// Via [ValueConverter] is possible to convert object from input [Stream] type to own stream [value].
  /// Returns [Future] to await and register other callbacks.
  Future onFuture(Future future, {ValueConverter? converter}) => future
      .then((value) => setValue(converter == null ? value : converter(value)));

  /// Subscribes this field to given [Stream].
  /// Controller will subscribe to input stream and will listen for changes and populate this changes into own stream.
  /// Via [ValueConverter] is possible to convert object from input [Stream] type to own stream [value].
  /// [StreamSubscription] is automatically closed during dispose phase of [FieldControl].
  /// Returns [FieldSubscription] for manual cancellation.
  FieldSubscription subscribeTo(Stream stream,
      {Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      ValueConverter? converter}) {
    return _addSub(
      stream.listen(
        (data) {
          if (converter != null) {
            final result = converter(data);

            if (result is Future) {
              result.then((value) => setValue(value)).catchError((err) {
                printDebug(err);
              });
            } else {
              setValue(result);
            }
          } else {
            setValue(data);
          }
        },
      ),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  FieldSubscription subscribe(void onData(T? event),
      {Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      bool current: true}) {
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

  @override
  FieldSubscription streamTo(FieldControl control,
      {Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      ValueConverter? converter}) {
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

  /// Clears subscribers, but didn't close [Stream] entirely.
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
      for (final sub in _subscriptions!) {
        sub._cancelStreamSub();
      }

      _subscriptions = null;
    }
  }

  /// Cancels and removes specific subscription
  void cancelSubscription(FieldSubscription subscription,
      {bool dispose: true}) {
    if (_subscriptions != null) {
      _subscriptions!.remove(subscription);

      if (dispose) {
        subscription._cancelStreamSub();
      }

      if (_subscriptions!.isEmpty) {
        _subscriptions = null;
      }
    }
  }

  /// Checks if given [subscription] is subscribed to [Stream] and is active.
  bool isSubscriptionValid(FieldSubscription subscription) =>
      isActive && _subscriptions!.contains(subscription);

  @override
  String toString() {
    return value?.toString() ?? '${super.toString()}: [NULL]';
  }
}

/// Standard [Sink] for [FieldControl].
class FieldSink<T> extends Sink<T> {
  /// Parent [FieldControl] to pass value in.
  FieldControl? _target;

  /// Initializes [Sink] with [target] Field.
  FieldSink(FieldControl<T> target) {
    _target = target;
  }

  @override
  void add(T data) {
    if (_target != null) {
      _target!.setValue(data);
    }
  }

  @override
  void close() {
    _target = null;
  }
}

/// Extended [FieldSink] with converter for [FieldControl]
/// Converts [value] and then sends it to Field.
class FieldSinkConverter<T> extends FieldSink<dynamic> {
  /// Value Converter - initialized in constructor
  final ValueConverter<T> converter;

  /// Initializes [Sink] with [target] Field and value [converter].
  FieldSinkConverter(FieldControl<T> target, this.converter) : super(target) {
    assert(converter != null);
  }

  @override
  void add(dynamic data) {
    if (_target != null) {
      _target!.setValue(converter(data));
    }
  }
}

// TODO: move to WIDGET folder in v1.1
/// Extends [StreamBuilder] and adds some functionality to be used easily with [FieldControl].
/// If no [Widget] is [build] then empty [Container] is returned.
class FieldStreamBuilder<T> extends StreamBuilder<T> {
  /// Stream based Widget builder. Listening [FieldControlStream.stream] about changes.
  /// [control] - required Stream controller. [FieldControl] or [FieldControlSub].
  /// [builder] - required Widget builder. [AsyncSnapshot] is passing data to handle.
  FieldStreamBuilder({
    Key? key,
    required FieldControlStream<T> control,
    required AsyncWidgetBuilder<T> builder,
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

// TODO: move to WIDGET folder in v1.1
/// Extended [FieldStreamBuilder] providing data check above [AsyncSnapshot] and calling corresponding build function.
class FieldBuilder<T> extends FieldStreamBuilder<T> {
  /// Stream based Widget builder. Listening [FieldControlStream.stream] about changes.
  /// [control] - required Stream controller. [FieldControl] or [FieldControlSub].
  /// [builder] - required Widget builder. Non 'null' [T] value is passed directly.
  /// [noData] - Widget to show, when value is 'null'.
  /// [nullOk] - Determine where to handle 'null' values. 'true' - 'null' will be passed to [builder].
  FieldBuilder({
    Key? key,
    required FieldControlStream<T> control,
    required ControlWidgetBuilder<T?> builder,
    WidgetBuilder? noData,
    bool nullOk: false,
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

              return Container();
            });
}

// TODO: remove in v1.1
/// Will be removed in v1.1 - use [ControlBuilderGroup] instead.
/// Subscribes to all given [controls] and notifies about changes. Build is called whenever value in one of [FieldControl] is changed.
class FieldBuilderGroup extends StatefulWidget {
  final List<FieldControlStream> controls;
  final ControlWidgetBuilder<List?> builder;

  /// Multiple Stream based Widget builder. Listening [FieldControlStream.stream] about changes.
  /// [controls] - List of controls to subscribe about value changes. [FieldControl] and [FieldControlSub].
  /// [builder] - Values to builder are passed in same order as [controls] are. Also 'null' values are passed in.
  const FieldBuilderGroup({
    Key? key,
    required this.controls,
    required this.builder,
  }) : super(key: key);

  @override
  _FieldBuilderGroupState createState() => _FieldBuilderGroupState();
}

/// State of [FieldBuilderGroup].
/// Subscribes to all provided Streams.
class _FieldBuilderGroupState extends State<FieldBuilderGroup> {
  /// Current values.
  List? _values;

  /// All active subs.
  final _subs = <FieldSubscription>[];

  /// Maps values from controls to List.
  List _mapValues() =>
      widget.controls.map((item) => item.value).toList(growable: false);

  @override
  void initState() {
    super.initState();

    _values = _mapValues();
    _initSubs();
  }

  void _initSubs() {
    widget.controls.forEach((controller) => _subs.add(controller.subscribe(
          (data) => setState(() {
            _values = _mapValues();
          }),
          current: false,
        )));
  }

  @override
  void didUpdateWidget(FieldBuilderGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controls != oldWidget.controls) {
      _subs.forEach((item) => item.cancel());
      _subs.clear();

      _initSubs();
    }

    List initial = _values!;
    List current = _mapValues();

    if (initial.length == current.length) {
      for (int i = 0; i < initial.length; i++) {
        if (initial[i] != current[i]) {
          setState(() {
            _values = current;
          });
          break;
        }
      }
    } else {
      setState(() {
        _values = current;
      });
    }
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

/// Extended version of [FieldControl] specified to [List].
class ListControl<T> extends FieldControl<List<T>> {
  /// Returns number of items in list.
  int get length => value!.length;

  /// Return true if there is no item.
  @override
  bool get isEmpty => value == null || value!.isEmpty;

  /// Return true if there is one or more items.
  @override
  bool get isNotEmpty => value != null && value!.isNotEmpty;

  bool nullable = false;

  /// [FieldControl] of [List].
  ListControl([Iterable<T>? items]) {
    final list = <T>[];
    if (items != null) {
      list.addAll(items);
    }

    super.setValue(list);
  }

  /// Returns the object at given index.
  T operator [](int index) => value![index];

  /// [List.last]
  T get last => value!.last;

  /// [List.first]
  T get first => value!.first;

  /// Filters data into given [controller].
  StreamSubscription filterTo(FieldControl controller,
      {Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      ValueConverter? converter,
      Predicate<T>? filter}) {
    return subscribe(
      (data) {
        if (filter != null) {
          data = data!.where(filter).toList();
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
  void setValue(Iterable<T>? items, {bool notifyListeners: true}) {
    value!.clear();

    if (items != null) {
      value!.addAll(items);
    }

    if (notifyListeners) {
      notify();
    }
  }

  /// Adds item to List and notifies stream.
  void add(T item) {
    value!.add(item);

    notify();
  }

  /// Adds all items to List and notifies stream.
  void addAll(Iterable<T> items) {
    value!.addAll(items);

    notify();
  }

  /// Adds item to List at given index and notifies stream.
  void insert(int index, T item) {
    value!.insert(index, item);

    notify();
  }

  /// Replaces first item in List for given [test]
  bool replace(T item, Predicate<T> test, [bool notify = true]) {
    final index = value!.indexWhere(test);

    final replace = index >= 0;

    if (replace) {
      value!.removeAt(index);
      value!.insert(index, item);

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
    final removed = value!.remove(item);

    notify();

    return removed;
  }

  /// Removes item from List at given index and notifies stream.
  T removeAt(int index) {
    final T item = value!.removeAt(index);

    notify();

    return item;
  }

  /// [Iterable.removeWhere].
  void removeWhere(Predicate<T> test) {
    value!.removeWhere(test);
    notify();
  }

  /// Swaps position of items at given indexes
  void swap(int indexA, int indexB) {
    T a = value![indexA];
    T b = value![indexB];

    value!.removeAt(indexA);
    value!.insert(indexA, b);

    value!.removeAt(indexB);
    value!.insert(indexB, a);

    notify();
  }

  /// [Iterable.clear].
  void clear({bool disposeItems: false}) {
    if (disposeItems) {
      value!.forEach((item) {
        if (item is Disposable) {
          item.dispose();
        }
      });
    }

    setValue(null);
  }

  /// [Iterable.sort].
  void sort([int compare(T a, T b)?]) {
    value!.sort(compare);
    notify();
  }

  /// [Iterable.shuffle].
  void shuffle([Random? random]) {
    value!.shuffle(random);
    notify();
  }

  /// [Iterable.map].
  Iterable<E> map<E>(E f(T item)) => value!.map(f);

  /// [Iterable.contains].
  bool contains(Object object) => value!.contains(object);

  /// [Iterable.forEach].
  void forEach(void f(T item)) => value!.forEach(f);

  /// [Iterable.reduce].
  T reduce(T combine(T value, T element)) => value!.reduce(combine);

  /// [Iterable.fold].
  E fold<E>(E initialValue, E combine(E previousValue, T element)) =>
      value!.fold(initialValue, combine);

  /// [Iterable.every].
  bool every(bool test(T element)) => value!.every(test);

  /// [Iterable.join].
  String join([String separator = ""]) => value!.join(separator);

  /// [Iterable.any].
  bool any(bool test(T element)) => value!.any(test);

  /// [Iterable.toList].
  List<T> toList({bool growable = true}) => value!.toList(growable: growable);

  /// [Iterable.toSet].
  Set<T> toSet() => value!.toSet();

  /// [Iterable.take].
  Iterable<T> take(int count) => value!.take(count);

  /// [Iterable.takeWhile].
  Iterable<T> takeWhile(bool test(T value)) => value!.takeWhile(test);

  /// [Iterable.skip].
  Iterable<T> skip(int count) => value!.skip(count);

  /// [Iterable.skipWhile].
  Iterable<T> skipWhile(bool test(T value)) => value!.skipWhile(test);

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T firstWhere(Predicate<T> test) => value!.firstWhere(test);

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T lastWhere(Predicate<T> test) => value!.lastWhere(test);

  /// [Iterable.where].
  Iterable<T> where(Predicate<T> test) => value!.where(test);

  /// [Iterable.indexWhere]
  int indexWhere(Predicate<T> test, [int start = 0]) =>
      value!.indexWhere(test, start);

  /// [List.lastIndexWhere].
  int lastIndexWhere(bool test(T element), [int? start]) =>
      value!.lastIndexWhere(test, start);

  /// [Iterable.indexOf]
  int indexOf(T object) => value!.indexOf(object);

  /// [List.lastIndexOf].
  int lastIndexOf(T element, [int? start]) =>
      value!.lastIndexOf(element, start);

  /// [List.sublist].
  List<T> sublist(int start, [int? end]) => value!.sublist(start, end);

  /// [List.getRange].
  Iterable<T> getRange(int start, int end) => value!.getRange(start, end);

  /// [List.asMap].
  Map<int, T> asMap() => value!.asMap();

  @override
  void dispose() {
    super.dispose();

    _value!.clear();
  }
}

// TODO: move to WIDGET folder in v1.1
/// Extended [FieldStreamBuilder] providing data check above [AsyncSnapshot] and calling corresponding build function.
class ListBuilder<T> extends FieldStreamBuilder<List<T>?> {
  /// Stream based Widget builder. Listening [FieldControlStream.stream] about changes.
  /// [control] - required Stream controller. [FieldControl] or [FieldControlSub].
  /// [builder] - required Widget builder. Only non empty [List] is passed directly to handle.
  /// [noData] - Widget to show, when List is empty.
  /// [nullOk] - Determine where to handle empty List. 'true' - empty List will be passed to [builder].
  ListBuilder({
    Key? key,
    required FieldControl<List<T>> control,
    required ControlWidgetBuilder<List<T>> builder,
    WidgetBuilder? noData,
    bool nullOk: false,
  }) : super(
          key: key,
          control: control,
          builder: (context, snapshot) {
            if ((snapshot.hasData && snapshot.data!.length > 0) || nullOk) {
              return builder(context, snapshot.data ?? const []);
            }

            if (noData != null) {
              return noData(context);
            }

            return Container();
          },
        );
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Extended [FieldControl] specified to control [LoadingStatus].
class LoadingControl extends FieldControl<LoadingStatus> {
  /// Returns true if [value] is [LoadingStatus.done].
  bool get isDone => value == LoadingStatus.done;

  /// Returns true if [value] is [LoadingStatus.progress].
  bool get inProgress => value == LoadingStatus.progress;

  /// Returns true if [value] is [LoadingStatus.error].
  bool get hasError => value == LoadingStatus.error;

  /// Returns true if [message] is not null.
  bool get hasMessage => message != null;

  /// Inner message of LoadingStatus.
  /// Can be used to hold error or any other loading message.
  dynamic message;

  /// [FieldControl] of [LoadingStatus].
  LoadingControl([LoadingStatus status = LoadingStatus.initial])
      : super(status);

  /// Changes status and sets inner message.
  void setStatus(LoadingStatus status, {dynamic msg}) {
    message = msg;

    setValue(status);
  }

  /// Changes status to [LoadingStatus.progress] and sets inner message.
  void progress({dynamic msg}) => setStatus(LoadingStatus.progress, msg: msg);

  /// Changes status to [LoadingStatus.done] and sets inner message.
  void done({dynamic msg}) => setStatus(LoadingStatus.done, msg: msg);

  /// Changes status to [LoadingStatus.error] and sets inner message.
  void error({dynamic msg}) => setStatus(LoadingStatus.error, msg: msg);

  /// Changes status to [LoadingStatus.outdated] and sets inner message.
  void outdated({dynamic msg}) => setStatus(LoadingStatus.outdated, msg: msg);

  /// Changes status to [LoadingStatus.unknown] and sets inner message.
  void unknown({dynamic msg}) => setStatus(LoadingStatus.unknown, msg: msg);

  /// Changes status based on given [loading] value and sets inner message.
  /// 'true' - [LoadingStatus.progress].
  /// 'false' - [LoadingStatus.done].
  void status(bool loading, {dynamic msg}) =>
      loading ? progress(msg: msg) : done(msg: msg);
}

// TODO: move to WIDGET folder in v1.1
/// Extended [FieldStreamBuilder] version specified to build [LoadingStatus] states.
/// Internally uses [CaseWidget] to animate Widget crossing.
class LoadingBuilder extends FieldStreamBuilder<LoadingStatus?> {
  /// Builds Widget based on current [LoadingStatus].
  /// Uses [CaseWidget] to handle current state and Widget animation.
  ///
  /// [initial] - Initial Widget before loading starts (barely used).
  /// [progress] - Loading Widget, by default [CircularProgressIndicator] is build.
  /// [done] - Widget when loading is completed.
  /// [error] - Error Widget, by default [Text] with [LoadingControl.message] is build.
  /// [outdated], [unknown] - Mostly same as [done] with some badge.
  /// [transition] - Transition between Widgets. By default [CrossTransitions.fadeOutFadeIn] is used.
  /// [transitions] - Case specific transitions.
  ///
  ///  If status don't have default builder, empty [Container] is build.
  ///  'null' is considered as [LoadingStatus.initial].
  LoadingBuilder({
    Key? key,
    required LoadingControl control,
    WidgetBuilder? initial,
    WidgetBuilder? progress,
    WidgetBuilder? done,
    WidgetBuilder? error,
    WidgetBuilder? outdated,
    WidgetBuilder? unknown,
    WidgetBuilder? general,
    CrossTransition? transition,
    Map<LoadingStatus, CrossTransition>? transitions,
  }) : super(
          key: key,
          control: control,
          builder: (context, snapshot) {
            final state =
                snapshot.hasData ? snapshot.data : LoadingStatus.initial;

            return CaseWidget(
              activeCase: state,
              builders: {
                LoadingStatus.initial: initial,
                LoadingStatus.progress: progress ??
                    general ??
                    (context) => Center(child: CircularProgressIndicator()),
                LoadingStatus.done: done,
                LoadingStatus.error: error ??
                    general ??
                    (context) =>
                        Center(child: Text(control.message ?? 'error')),
                LoadingStatus.outdated: outdated,
                LoadingStatus.unknown: unknown,
              },
              placeholder: general ?? (context) => Container(),
              transition: CrossTransition(
                builder: CrossTransitions.fadeOutFadeIn(
                    backgroundColor: Colors.transparent),
              ),
              transitions: transitions,
            );
          },
        );
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Extended version of [FieldControl] specified to [bool].
class BoolControl extends FieldControl<bool> {
  /// Checks if [value] is 'true'.
  bool get isTrue => value == true;

  /// Checks if [value] is 'false' or 'null'.
  bool get isFalse => value == false || value == null;

  /// [FieldControl] of [bool].
  /// Default [value] is 'false'.
  BoolControl([bool value = false]) : super(value);

  /// Toggles current value and notifies listeners.
  /// 'true' -> 'false'
  /// 'false' -> 'true'
  void toggle() {
    setValue(!value!);
  }

  /// Sets value to 'true'.
  /// Listeners are notified if [value] is changed.
  void setTrue() => setValue(true);

  /// Sets value to 'false'.
  /// Listeners are notified if [value] is changed.
  void setFalse() => setValue(false);
}

/// Extended version of [FieldControl] specified to [String].
class StringControl extends FieldControl<String?> {
  /// Returns 'true' if value is 'null' or empty String.
  @override
  bool get isEmpty => value?.isEmpty ?? true;

  /// Returns 'true' if value is not 'null' and not empty.
  @override
  bool get isNotEmpty => value?.isNotEmpty ?? false;

  /// Current regex for validation.
  /// [setWithRegex] will be called if regex is not null.
  String? regex;

  /// Checks if [regex] is filled and validation is required.
  bool get requestValidation => regex != null;

  /// [FieldControl] of [String].
  StringControl([String? value]) : super(value);

  /// [FieldControl] of [String] with [regex] validation.
  StringControl.withRegex({String? value, this.regex}) {
    setWithRegex(value);
  }

  @override
  void setValue(String? value, {bool notifyListeners: true}) {
    if (requestValidation) {
      setWithRegex(value, notifyListeners: notifyListeners);
    } else {
      super.setValue(value, notifyListeners: notifyListeners);
    }
  }

  /// Sets given [value] only if [regex] matches.
  ///
  /// [regex] - override of [StringControl.regex] -> one of them can't be 'null'.
  ///
  /// Regex is typically used with [StringControl.withRegex] constructor and then setting value via [setValue] or [value] setter.
  void setWithRegex(String? value,
      {String? regex, bool notifyListeners: true}) {
    assert(regex != null || this.regex != null);

    regex ??= this.regex;

    if (RegExp(regex!).hasMatch(value ?? '')) {
      super.setValue(value, notifyListeners: notifyListeners);
    } else {
      printDebug('value is not within regex $regex');
    }
  }
}

/// Extended version of [FieldControl] specified to [double].
class DoubleControl extends FieldControl<double> {
  /// Inclusive lower bound value;
  double min = 0.0;

  /// Inclusive upper bound value;
  double max = 0.0;

  /// Checks if clamping is required
  bool get clamp => min != 0.0 || max != 0.0;

  /// Checks if clamping is required and [value] is equal to [min].
  bool get atMin => clamp && value == min;

  /// Checks if clamping is required and [value] is equal to [max].
  bool get atMax => clamp && value == max;

  /// [FieldControl] of [double].
  DoubleControl([double value = 0.0]) : super(value);

  /// [FieldControl] of [double] with [min] - [max] clamping.
  DoubleControl.inRange({double value: 0.0, this.min: 0.0, this.max: 1.0}) {
    setInRange(value);
  }

  void setValue(double? value, {bool notifyListeners: true}) {
    if (clamp) {
      setInRange(value, notifyListeners: notifyListeners);
    } else {
      super.setValue(value, notifyListeners: notifyListeners);
    }
  }

  //TODO: currently have two purposes -> clamping and setting in range.
  /// Sets given [value] clamped to [min] - [max] range.
  ///
  /// [min] - Override of [DoubleControl.min].
  /// [max] - Override of [DoubleControl.max].
  ///
  /// Range is typically used with [DoubleControl.inRange] constructor and then setting value via [setValue] or [value] setter.
  void setInRange(double? value,
      {double? min, double? max, bool notifyListeners: true}) {
    if (clamp) {
      super.setValue(
          (value ?? min ?? this.min).clamp(min ?? this.min, max ?? this.max));
    } else {
      if (value! >= min! && value <= max!) {
        super.setValue(value, notifyListeners: notifyListeners);
      } else {
        printDebug('value is not within range $min - $max');
      }
    }
  }
}

/// Extended version of [FieldControl] specified to [int].
class IntegerControl extends FieldControl<int> {
  /// Inclusive lower bound value;
  int min = 0;

  /// Inclusive upper bound value;
  int max = 0;

  /// Checks if clamping is required
  bool get clamp => min != 0 || max != 0;

  /// Checks if clamping is required and [value] is equal to [min].
  bool get atMin => clamp && value == min;

  /// Checks if clamping is required and [value] is equal to [max].
  bool get atMax => clamp && value == max;

  /// [FieldControl] of [double].
  IntegerControl([int value = 0]) : super(value);

  /// [FieldControl] of [double] with [min] - [max] clamping.
  IntegerControl.inRange({int value: 0, this.min: 0, this.max: 100}) {
    setInRange(value);
  }

  void setValue(int? value, {bool notifyListeners: true}) {
    if (clamp) {
      setInRange(value, notifyListeners: notifyListeners);
    } else {
      super.setValue(value, notifyListeners: notifyListeners);
    }
  }

  //TODO: currently have two purposes -> clamping and setting in range.
  /// Sets given [value] clamped to [min] - [max] range.
  ///
  /// [min] - Override of [DoubleControl.min].
  /// [max] - Override of [DoubleControl.max].
  ///
  /// Range is typically used with [DoubleControl.inRange] constructor and then setting value via [setValue] or [value] setter.
  void setInRange(int? value,
      {int? min, int? max, bool notifyListeners: true}) {
    if (clamp) {
      super.setValue(
          (value ?? min ?? this.min).clamp(min ?? this.min, max ?? this.max));
    } else {
      if (value! >= min! && value <= max!) {
        super.setValue(value, notifyListeners: notifyListeners);
      } else {
        printDebug('value is not within range $min - $max');
      }
    }
  }
}
