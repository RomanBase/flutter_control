import 'dart:async';

import 'package:flutter_control/core.dart';

typedef Converter<T> = T Function(dynamic);

class FieldController<T> implements Disposable {
  final _stream = StreamController<T>.broadcast();

  List<StreamSubscription> _subscriptions;

  Sink<T> get sink => FieldSink<T>(this);

  T _value;

  T get value => _value;

  FieldController([T value]) {
    if (value != null) {
      setValue(value);
    }
  }

  FieldController.of(Stream stream, {Function onError, void onDone(), bool cancelOnError, Converter<T> converter}) {
    subscribeTo(stream, onError: onError, onDone: onDone, cancelOnError: cancelOnError, converter: converter);
  }

  void setValue(T value) {
    _value = value;
    _stream.add(value);
  }

  void copyValue(FieldController<T> controller) {
    setValue(controller.value);
  }

  Sink<dynamic> sinkConverter(Converter<T> converter) {
    return FieldSinkConverter(this, converter);
  }

  StreamSubscription subscribe(void onData(T event), {Function onError, void onDone(), bool cancelOnError}) {
    final subscription = _stream.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

    if (_subscriptions == null) {
      _subscriptions = List();
    }

    _subscriptions.add(subscription);

    return subscription;
  }

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

  void clearSubscriptions() {
    if (_subscriptions != null) {
      for (final sub in _subscriptions) {
        sub.cancel();
      }

      _subscriptions = null;
    }
  }
}

class FieldSink<T> extends Sink<T> {
  FieldController _target;

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

class FieldSinkConverter<T> extends FieldSink<dynamic> {
  final Converter<T> converter;

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

class FieldBuilder<T> extends StreamBuilder<T> {
  FieldBuilder({Key key, @required FieldController<T> controller, @required AsyncWidgetBuilder<T> builder}) : super(key: key, initialData: controller._value, stream: controller._stream.stream, builder: builder);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) {
    Widget widget = super.build(context, currentSummary);

    return widget ?? Container();
  }
}
