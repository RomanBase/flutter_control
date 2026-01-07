part of '../../core.dart';

class FieldSubscription<T> extends ControlSubscription<T>
    implements StreamSubscription<T?> {
  final StreamSubscription<T?> _sub;
  bool cancelOnError = false;

  FieldSubscription(this._sub);

  @override
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

/// Stream based version of [ObservableModel].
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
  @override
  bool get isActive => !_stream.isClosed;

  /// Returns true if current stream is closed.
  bool get isClosed => _stream.isClosed;

  /// Stream centric version of [ObservableModel].
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
      void Function()? onDone,
      bool cancelOnError = false,
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
  @override
  void notify() {
    if (!_stream.isClosed) {
      _stream.add(_value);
    }
  }

  /// Returns [Sink] with custom [ValueConverter].
  Sink sinkConverter(ValueConverter<T> converter) =>
      FieldSinkConverter(this, converter);

  /// Creates sub and stores reference for later dispose..
  FieldSubscription<U> _addSub<U>(StreamSubscription<U?> subscription,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false}) {
    final sub = FieldSubscription<U>(subscription)
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
          .then(
              (value) => setValue(converter == null ? value : converter(value)))
          .catchError((err) {
        printDebug(err);
      });

  /// Subscribes this field to given [Stream].
  /// Controller will subscribe to input stream and will listen for changes and populate this changes into own stream.
  /// Via [ValueConverter] is possible to convert object from input [Stream] type to own stream [value].
  /// [StreamSubscription] is automatically closed during dispose phase of [FieldControl].
  /// Returns [FieldSubscription] for manual cancellation.
  FieldSubscription subscribeTo(Stream stream,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false,
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

  FieldSubscription<T> subscribeStream(void Function(T? event) onData,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false,
      bool current = true}) {
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
  void cancel(ControlSubscription subscription) {
    assert(subscription is FieldSubscription);
    final sub = subscription as FieldSubscription;

    _subscriptions.remove(sub);

    subscription.invalidate();
    sub._cancelStreamSub();
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
class FieldSink<T> implements Sink<T> {
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
  FieldSinkConverter(FieldControl<T> super.target, this.converter);

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
/// TODO [4.2.0]: ready to refactor
class ListControl<T> extends FieldControl<List<T>> {
  @override
  List<T> get value => super.value!;

  @override
  set value(List<T>? value) => super.setValue(value ?? []);

  /// Returns number of items in list.
  int get length => value.length;

  /// Return true if there is no item.
  @override
  bool get isEmpty => value.isEmpty;

  /// Return true if there is one or more items.
  @override
  bool get isNotEmpty => value.isNotEmpty;

  /// Returns the object at given index.
  T? operator [](int index) => containsIndex(index) ? value[index] : null;

  /// [List.last]
  T? get last => isNotEmpty ? value.last : null;

  /// [List.first]
  T? get first => isNotEmpty ? value.first : null;

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
      void Function()? onDone,
      bool cancelOnError = false,
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
  void setValue(Iterable<T>? value,
      {bool notify = true, bool forceNotify = false}) {
    this.value.clear();

    if (value != null) {
      this.value.addAll(value);
    }

    if (notify || forceNotify) {
      this.notify();
    }
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
    for (final item in items) {
      replace(item, test, false);
    }

    notify();
  }

  /// Removes item from List and notifies stream.
  bool remove(T? item) {
    final removed = value.remove(item);

    if (removed) {
      notify();
    }

    return removed;
  }

  /// Removes item from List at given index and notifies stream.
  T removeAt(int index) {
    final T item = value.removeAt(index);

    notify();

    return item;
  }

  /// [Iterable.removeWhere].
  void removeWhere(Predicate<T> test) {
    value.removeWhere(test);
    notify();
  }

  /// Swaps position of items at given indexes
  void swap(int indexA, int indexB) {
    T a = value[indexA];
    T b = value[indexB];

    value.removeAt(indexA);
    value.insert(indexA, b);

    value.removeAt(indexB);
    value.insert(indexB, a);

    notify();
  }

  /// [Iterable.clear].
  void clear({bool disposeItems = false}) {
    if (disposeItems) {
      for (final item in value) {
        if (item is Disposable) {
          item.dispose();
        }
      }
    }

    setValue(null);
  }

  /// [Iterable.sort].
  void sort([int Function(T a, T b)? compare]) {
    value.sort(compare);
    notify();
  }

  /// Reorders list
  void reorder(int oldIndex, int newIndex) {
    value.reorder(oldIndex, newIndex);
    notify();
  }

  /// [Iterable.shuffle].
  void shuffle([math.Random? random]) {
    value.shuffle(random);
    notify();
  }

  /// [Iterable.map].
  Iterable<E> map<E>(E Function(T item) f) => value.map(f);

  /// [Iterable.contains].
  bool contains(Object object) => value.contains(object);

  /// [Iterable.forEach].
  void forEach(void Function(T item) f) => value.forEach(f);

  /// [Iterable.reduce].
  T reduce(T Function(T value, T element) combine) => value.reduce(combine);

  /// [Iterable.fold].
  E fold<E>(E initialValue, E Function(E previousValue, T element) combine) =>
      value.fold(initialValue, combine);

  /// [Iterable.every].
  bool every(bool Function(T element) test) => value.every(test);

  /// [Iterable.join].
  String join([String separator = ""]) => value.join(separator);

  /// [Iterable.any].
  bool any(bool Function(T element) test) => value.any(test);

  /// [Iterable.toList].
  List<T> toList({bool growable = true}) => value.toList(growable: growable);

  /// [Iterable.toSet].
  Set<T> toSet() => value.toSet();

  /// [Iterable.take].
  Iterable<T> take(int count) => value.take(count);

  /// [Iterable.takeWhile].
  Iterable<T> takeWhile(bool Function(T value) test) => value.takeWhile(test);

  /// [Iterable.skip].
  Iterable<T> skip(int count) => value.skip(count);

  /// [Iterable.skipWhile].
  Iterable<T> skipWhile(bool Function(T value) test) => value.skipWhile(test);

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T? firstWhere(Predicate<T> test) {
    try {
      return value.firstWhere(test);
    } on StateError {
      return null;
    }
  }

  /// [Iterable.firstWhere].
  /// If no element satisfies [test], then return null.
  T? lastWhere(Predicate<T> test) {
    try {
      return value.lastWhere(test);
    } on StateError {
      return null;
    }
  }

  /// [Iterable.where].
  Iterable<T> where(Predicate<T> test) => value.where(test);

  /// [Iterable.indexWhere]
  int indexWhere(Predicate<T> test, [int start = 0]) =>
      value.indexWhere(test, start);

  /// [List.lastIndexWhere].
  int lastIndexWhere(bool Function(T element) test, [int? start]) =>
      value.lastIndexWhere(test, start);

  /// [Iterable.indexOf]
  int indexOf(T object) => value.indexOf(object);

  /// [List.lastIndexOf].
  int lastIndexOf(T element, [int? start]) => value.lastIndexOf(element, start);

  /// [List.sublist].
  List<T> sublist(int start, [int? end]) => value.sublist(start, end);

  /// [List.getRange].
  Iterable<T> getRange(int start, int end) => value.getRange(start, end);

  /// [List.asMap].
  Map<int, T> asMap() => value.asMap();

  @override
  void dispose() {
    super.dispose();

    value.clear();
  }
}

//########################################################################################
//########################################################################################
//########################################################################################

enum LoadingStatus {
  initial,
  progress,
  done,
  error,
  outdated,
  unknown,
}

/// Extended [FieldControl] specified to control [LoadingStatus].
/// TODO [4.2.0]: ready to refactor
class LoadingControl extends ControlObservable<LoadingStatus> {
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
  LoadingControl([super.status = LoadingStatus.initial]);

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
}
