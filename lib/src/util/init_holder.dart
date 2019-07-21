import 'package:flutter_control/core.dart';

class InitHolder<T> {
  T _value;
  ValueGetter<T> _builder;

  bool get isActive => _builder != null;

  bool get isBuild => _value != null;

  InitHolder({ValueGetter<T> builder}) {
    _builder = builder;
  }

  bool set({@required ValueGetter<T> builder, bool override: false}) {
    if (_builder == null || override) {
      _builder = builder;
      return true;
    }

    return false;
  }

  T get() => _value ?? (_value = _builder());
}
