import 'dart:async';

import 'package:flutter_control/core.dart';

/// Enclosure and adds functionality to standard Stream - StreamBuilder pattern.
/// Use then FieldBuilder for easier integration into Widget.
class FieldController<T> implements Disposable {
  /// Current broadcast StreamController.
  final _stream = StreamController<T>.broadcast();

  /// List of subscribers for later dispose.
  List<StreamSubscription> _subscriptions;

  /// Default sink of this controller.
  Sink<T> get sink => FieldSink<T>(this);

  /// return true if current stream is closed.
  bool get isClosed => _stream.isClosed;

  /// Current value.
  T _value;

  /// returns current value - last in stream.
  T get value => _value;

  /// Initialize controller and stream with default value.
  FieldController([T value]) {
    if (value != null) {
      setValue(value);
    }
  }

  /// Initialize controller and subscribe it to given stream.
  /// Controller will subscribe to input stream and will listen for changes and populate this changes into own stream.
  /// Via converter is possible to convert value from input stream type to own stream value.
  FieldController.of(Stream stream, {Function onError, void onDone(), bool cancelOnError, Converter<T> converter}) {
    subscribeTo(stream, onError: onError, onDone: onDone, cancelOnError: cancelOnError, converter: converter);
  }

  /// Sets the value and adds it to the stream.
  /// If given object is same as current value nothing happens.
  void setValue(T value) {
    if (_value == value) {
      return;
    }

    _value = value;

    if (!_stream.isClosed) {
      _stream.add(value);
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

  /// Initialize Sink with custom Converter.
  Sink<dynamic> sinkConverter(Converter<T> converter) => FieldSinkConverter(this, converter);

  /// Subscribe to current stream.
  /// Subscriptions are automatically closed during dispose phase of FieldController.
  StreamSubscription subscribe(void onData(T event), {Function onError, void onDone(), bool cancelOnError}) {
    final subscription = _stream.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

    if (_subscriptions == null) {
      _subscriptions = List();
    }

    _subscriptions.add(subscription);

    return subscription;
  }

  /// Subscribe controller to given steam.
  /// Controller will subscribe to input stream and will listen for changes and populate this changes into own stream.
  /// Via converter is possible to convert value from input stream type to own stream value.
  /// Subscription is automatically closed during dispose phase of FieldController.
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

  @override
  void dispose() {
    _stream.close();

    clearSubscriptions();
  }

  /// Manually clears are subscriptions.
  void clearSubscriptions() {
    if (_subscriptions != null) {
      for (final sub in _subscriptions) {
        sub.cancel();
      }

      _subscriptions = null;
    }
  }

  /// Returns FieldBuilder for this Controller.
  FieldBuilder<T> builder({@required AsyncWidgetBuilder<T> builder}) => FieldBuilder<T>(controller: this, builder: builder);
}

/// Enclosure and adds functionality to standard Stream - StreamBuilder pattern.
/// Use then FieldBuilder for easier integration into Widget.
class FieldListController<T> extends FieldController<List<T>> {
  /// returns number of items in list.
  int get length => value.length;

  /// return true if there is no item.
  bool get isEmpty => value.isEmpty;

  /// Default constructor.
  FieldListController([Iterable<T> items]) {
    final list = List<T>();
    if (items != null) {
      list.addAll(items);
    }

    super.setValue(list);
  }

  /// Returns the object at given index.
  T operator [](int index) => value[index];

  @override
  void setValue(List<T> items) {
    value.clear();

    if (items != null) {
      value.addAll(items);
    }

    super.setValue(value);
  }

  /// Adds item to List and notifies stream.
  void add(T item) {
    value.add(item);
    super.setValue(value);
  }

  /// Adds all items to List and notifies stream.
  void addAll(Iterable<T> items) {
    value.addAll(items);
    super.setValue(value);
  }

  /// Adds item to List at given index and notifies stream.
  void insert(int index, T item) {
    value.insert(index, item);
    super.setValue(value);
  }

  /// Removes item from List and notifies stream.
  void remove(T item) {
    value.remove(item);
    super.setValue(value);
  }

  /// Removes item from List at given index and notifies stream.
  void removeAt(int index) {
    value.removeAt(index);
    super.setValue(value);
  }
}

/// Shortcut for LoadingStatus Controller.
class LoadingController extends FieldController<LoadingStatus> {
  /// Return true if status is done.
  bool get isDone => value == LoadingStatus.done;

  /// Return true if status is progress.
  bool get inProgress => value == LoadingStatus.progress;

  /// Return true if status is error.
  bool get hasError => value == LoadingStatus.error;

  /// Inner message of LoadingStatus.
  String message;

  LoadingController([LoadingStatus status = LoadingStatus.progress]) : super(status);

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

/// Standard Sink for FieldController.
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

/// Sink with converter for FieldController
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

/// Extends from StreamBuilder - adds some functionality to be used easily with FieldController.
class FieldBuilder<T> extends StreamBuilder<T> {
  FieldBuilder({Key key, @required FieldController<T> controller, @required AsyncWidgetBuilder<T> builder}) : super(key: key, initialData: controller._value, stream: controller._stream.stream, builder: builder);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) {
    Widget widget = super.build(context, currentSummary);

    return widget ?? Container();
  }
}
