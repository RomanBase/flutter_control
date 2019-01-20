import 'dart:async';

import 'package:flutter_control/core.dart';

/// Enclosure and adds functionality to standard Stream - StreamBuilder pattern.
/// User then FieldBuilder for easier integration into Widget.
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

  /// Sets the value and adds it to stream.
  void setValue(T value) {
    _value = value;

    if (!_stream.isClosed) {
      _stream.add(value);
    }
  }

  /// Copy last value from input controller and sets it to own stream.
  void copyValue(FieldController<T> controller) {
    setValue(controller.value);
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
