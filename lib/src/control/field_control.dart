import 'dart:async';
import 'dart:math';

import 'package:flutter_control/core.dart';

class FieldSubscription<T> extends ControlSubscription<T>
    implements StreamSubscription<T?> {
  StreamSubscription<T?> _sub;
  bool cancelOnError = false;

  FieldSubscription(this._sub);

  bool get isActive => !isPaused && isValid;

  @override
  bool get isPaused => _sub.isPaused;

  Function _wrapOnDone(Function? handleDone) {
    return () {
      if (handleDone != null) {
        handleDone();
      }

      super.cancel();
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
    super.cancel();

    return _sub.cancel();
  }

  @override
  void onData(void Function(T? data)? handleData) {
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
    super.pause();

    _sub.pause(resumeSignal);
  }

  @override
  void resume() {
    super.resume();

    _sub.resume();
  }

  void _cancelStreamSub() {
    _sub.cancel();
  }

  @override
  void dispose() {
    super.dispose();

    cancel();
  }
}

/// {@macro action-control}
class FieldControl<T> extends ObservableModel<T?> {
  /// Current broadcast [StreamController].
  final StreamController<T?> _stream = StreamController<T?>.broadcast();

  /// List of subscribers for later dispose.
  final _subscriptions = <FieldSubscription>[];

  /// Default sink of this controller.
  /// Use [sinkConverter] to convert input data.
  Sink<T> get sink => FieldSink<T>(this);

  Stream<T?> get stream => _stream.stream;

  /// Current value.
  T? _value;

  @override
  T? get value => _value;

  @override
  bool get isValid => !_stream.isClosed;

  /// Checks if [Stream] is not closed.
  bool get isActive => !_stream.isClosed;

  /// Returns true if current stream is closed.
  bool get isClosed => _stream.isClosed;

  /// Initializes control and [Stream] with default [value].
  FieldControl([T? value]) {
    if (value != null) {
      setValue(value);
    }
  }

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

  @override
  void setValue(T? value, {bool notify = true, bool forceNotify = false}) {
    if (_value == value) {
      if (forceNotify) {
        this.notify();
      }

      return;
    }

    _value = value;

    if (notify || forceNotify) {
      this.notify();
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
  FieldSubscription<T> _addSub<T>(StreamSubscription<T?> subscription,
      {Function? onError, void onDone()?, bool cancelOnError: false}) {
    final sub = FieldSubscription<T>(subscription)
      ..onError(onError)
      ..onDone(onDone)
      ..cancelOnError = cancelOnError;

    sub.initSubscription(this);

    _subscriptions.add(sub);

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
    // ignore: cancel_subscriptions
    final subscription = stream.listen(
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
    );

    return _addSub(
      subscription,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  FieldSubscription<T> subscribe(ValueCallback<T?> action,
      {bool current = true, dynamic args}) {
    // ignore: cancel_subscriptions
    final subscription = _stream.stream.listen(action);

    if (value != null && current) {
      action(value);
    }

    return _addSub<T>(
      subscription,
      cancelOnError: false,
    );
  }

  FieldSubscription<T> subscribeStream(void onData(T? event),
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

    return _addSub<T>(
      subscription,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void cancel(ControlSubscription<T?> subscription) {
    assert(subscription is FieldSubscription);

    _subscriptions.remove(subscription);

    subscription.invalidate();
    (subscription as FieldSubscription)._cancelStreamSub();
  }

  /// Clears subscribers, but didn't close [Stream] entirely.
  void softDispose() {
    _clearSubscriptions();
  }

  /// Manually cancels and clears all subscriptions.
  void _clearSubscriptions() {
    for (final sub in _subscriptions) {
      sub._cancelStreamSub();
    }
  }

  @override
  void dispose() {
    _stream.close();

    _clearSubscriptions();
  }

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
  FieldSinkConverter(FieldControl<T> target, this.converter) : super(target);

  @override
  void add(dynamic data) {
    if (_target != null) {
      _target!.setValue(converter(data));
    }
  }
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Extended version of [FieldControl] specified to [List].
class ListControl<T> extends FieldControl<List<T>> {
  /// [value] can't be `null`.
  List<T> get _list => value!;

  /// Returns number of items in list.
  int get length => _list.length;

  /// Return true if there is no item.
  @override
  bool get isEmpty => _list.isEmpty;

  /// Return true if there is one or more items.
  @override
  bool get isNotEmpty => _list.isNotEmpty;

  /// Returns the object at given index.
  T? operator [](int index) => containsIndex(index) ? _list[index] : null;

  /// [List.last]
  T? get last => isNotEmpty ? _list.last : null;

  /// [List.first]
  T? get first => isNotEmpty ? _list.first : null;

  /// [FieldControl] of [List].
  ListControl([Iterable<T>? items]) {
    final list = <T>[];
    if (items != null) {
      list.addAll(items);
    }

    super.setValue(list);
  }

  /// Checks if [index] is within [value] bounds.
  bool containsIndex(int index) => length > 0 && index > -1 && index < length;

  /// Filters data into given [controller].
  StreamSubscription filterTo(FieldControl controller,
      {Function? onError,
      void onDone()?,
      bool cancelOnError: false,
      ValueConverter? converter,
      Predicate<T>? filter}) {
    return subscribeStream(
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

    _stream.add(_value);
  }

  @override
  void setValue(Iterable<T>? items,
      {bool notify: true, bool forceNotify: false}) {
    _list.clear();

    if (items != null) {
      _list.addAll(items);
    }

    if (notify || forceNotify) {
      this.notify();
    }
  }

  /// Adds item to List and notifies stream.
  void add(T item) {
    _list.add(item);

    notify();
  }

  /// Adds all items to List and notifies stream.
  void addAll(Iterable<T> items) {
    _list.addAll(items);

    notify();
  }

  /// Adds item to List at given index and notifies stream.
  void insert(int index, T item) {
    _list.insert(index, item);

    notify();
  }

  /// Replaces first item in List for given [test]
  bool replace(T item, Predicate<T> test, [bool notify = true]) {
    final index = _list.indexWhere(test);

    final replace = index >= 0;

    if (replace) {
      _list.removeAt(index);
      _list.insert(index, item);

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
  bool remove(T? item) {
    final removed = _list.remove(item);

    if (removed) {
      notify();
    }

    return removed;
  }

  /// Removes item from List at given index and notifies stream.
  T removeAt(int index) {
    final T item = _list.removeAt(index);

    notify();

    return item;
  }

  /// [Iterable.removeWhere].
  void removeWhere(Predicate<T> test) {
    _list.removeWhere(test);
    notify();
  }

  /// Swaps position of items at given indexes
  void swap(int indexA, int indexB) {
    T a = _list[indexA];
    T b = _list[indexB];

    _list.removeAt(indexA);
    _list.insert(indexA, b);

    _list.removeAt(indexB);
    _list.insert(indexB, a);

    notify();
  }

  /// [Iterable.clear].
  void clear({bool disposeItems: false}) {
    if (disposeItems) {
      _list.forEach((item) {
        if (item is Disposable) {
          item.dispose();
        }
      });
    }

    setValue(null);
  }

  /// [Iterable.sort].
  void sort([int compare(T a, T b)?]) {
    _list.sort(compare);
    notify();
  }

  /// [Iterable.shuffle].
  void shuffle([Random? random]) {
    _list.shuffle(random);
    notify();
  }

  /// [Iterable.map].
  Iterable<E> map<E>(E f(T item)) => _list.map(f);

  /// [Iterable.contains].
  bool contains(Object object) => _list.contains(object);

  /// [Iterable.forEach].
  void forEach(void f(T item)) => _list.forEach(f);

  /// [Iterable.reduce].
  T reduce(T combine(T value, T element)) => _list.reduce(combine);

  /// [Iterable.fold].
  E fold<E>(E initialValue, E combine(E previousValue, T element)) =>
      _list.fold(initialValue, combine);

  /// [Iterable.every].
  bool every(bool test(T element)) => _list.every(test);

  /// [Iterable.join].
  String join([String separator = ""]) => _list.join(separator);

  /// [Iterable.any].
  bool any(bool test(T element)) => _list.any(test);

  /// [Iterable.toList].
  List<T> toList({bool growable = true}) => _list.toList(growable: growable);

  /// [Iterable.toSet].
  Set<T> toSet() => _list.toSet();

  /// [Iterable.take].
  Iterable<T> take(int count) => _list.take(count);

  /// [Iterable.takeWhile].
  Iterable<T> takeWhile(bool test(T value)) => _list.takeWhile(test);

  /// [Iterable.skip].
  Iterable<T> skip(int count) => _list.skip(count);

  /// [Iterable.skipWhile].
  Iterable<T> skipWhile(bool test(T value)) => _list.skipWhile(test);

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T? firstWhere(Predicate<T> test) {
    try {
      return _list.firstWhere(test);
    } on StateError {
      return null;
    }
  }

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T? lastWhere(Predicate<T> test) {
    try {
      return _list.lastWhere(test);
    } on StateError {
      return null;
    }
  }

  /// [Iterable.where].
  Iterable<T> where(Predicate<T> test) => _list.where(test);

  /// [Iterable.indexWhere]
  int indexWhere(Predicate<T> test, [int start = 0]) =>
      _list.indexWhere(test, start);

  /// [List.lastIndexWhere].
  int lastIndexWhere(bool test(T element), [int? start]) =>
      _list.lastIndexWhere(test, start);

  /// [Iterable.indexOf]
  int indexOf(T object) => _list.indexOf(object);

  /// [List.lastIndexOf].
  int lastIndexOf(T element, [int? start]) => _list.lastIndexOf(element, start);

  /// [List.sublist].
  List<T> sublist(int start, [int? end]) => _list.sublist(start, end);

  /// [List.getRange].
  Iterable<T> getRange(int start, int end) => _list.getRange(start, end);

  /// [List.asMap].
  Map<int, T> asMap() => _list.asMap();

  @override
  void dispose() {
    super.dispose();

    _list.clear();
  }
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
  void setValue(String? value, {bool notify = true, bool forceNotify = false}) {
    if (requestValidation) {
      setWithRegex(value, notify: notify, forceNotify: forceNotify);
    } else {
      super.setValue(value, notify: notify, forceNotify: forceNotify);
    }
  }

  /// Sets given [value] only if [regex] matches.
  ///
  /// [regex] - override of [StringControl.regex] -> one of them can't be 'null'.
  ///
  /// Regex is typically used with [StringControl.withRegex] constructor and then setting value via [setValue] or [value] setter.
  void setWithRegex(String? value,
      {String? regex, bool notify = true, bool forceNotify = false}) {
    assert(regex != null || this.regex != null);

    regex ??= this.regex;

    if (RegExp(regex!).hasMatch(value ?? '')) {
      super.setValue(value, notify: notify, forceNotify: forceNotify);
    } else {
      printDebug('value [$value] has not match regex [$regex]');
    }
  }
}

/// Extended version of [FieldControl] specified to [num].
class NumberControl<T extends num> extends FieldControl<T> {
  /// Inclusive lower bound value;
  late T min;

  /// Inclusive upper bound value;
  late T max;

  /// Checks if clamping is required
  bool clamp = true;

  /// Checks if clamping is possible
  bool get clampable => min != max;

  /// Checks if clamping is required and [value] is equal to [min].
  bool get atMin => clamp && value == min;

  /// Checks if clamping is required and [value] is equal to [max].
  bool get atMax => clamp && value == max;

  /// [FieldControl] of [num].
  NumberControl([T? value]) : super(value) {
    setRange(null, null);
  }

  /// [FieldControl] of [num] with [min] - [max] clamping.
  /// [min] - default 0
  /// [max] - default 1
  NumberControl.inRange({T? value, T? min, T? max, bool clamp: true}) {
    this.clamp = clamp;
    setRange(min, max ?? _castValue(1));
    setValue(value);
  }

  void setRange(T? min, T? max) {
    this.min = min ?? _castValue(0);
    this.max = max ?? _castValue(0);
  }

  T _castValue(num value) {
    if (T is int) {
      return value.toInt() as T;
    } else {
      return value.toDouble() as T;
    }
  }

  void setValue(T? value, {bool notify = true, bool forceNotify = false}) {
    if (clampable) {
      if (clamp) {
        super.setValue(_castValue((value ?? min).clamp(min, max)),
            notify: notify, forceNotify: forceNotify);
      } else {
        if (value! >= min && value <= max) {
          super.setValue(value, notify: notify, forceNotify: forceNotify);
        } else {
          printDebug('value [$value] is not within range [$min - $max]');
        }
      }
    } else {
      super.setValue(value, notify: notify, forceNotify: forceNotify);
    }
  }
}
