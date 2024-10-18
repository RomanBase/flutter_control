part of '../core.dart';

typedef InitInjection<T> = void Function(T? item, dynamic args);

/// TODO: purpose ? Since v0 and never used :) But ControlFactory still uses 'empty' injector.
@Deprecated('Remove in future - support LateInitialization with macros later')
abstract class Injector {
  void inject<T>(T item, dynamic args);

  static Injector of(Map<Type, InitInjection> injectors,
          {InitInjection? other}) =>
      BaseInjector(injectors: injectors, other: other);
}

@Deprecated('Remove in future - support LateInitialization with macros later')
class BaseInjector implements Injector, Disposable {
  final _injectors = <Type, InitInjection>{};
  InitInjection? _other;

  BaseInjector({Map<Type, InitInjection>? injectors, InitInjection? other}) {
    if (injectors != null) {
      _injectors.addAll(injectors);
    }

    _other = other;
  }

  void setInjector<T>(InitInjection<T> inject) {
    if (T == dynamic) {
      _other = inject as void Function(dynamic, dynamic)?;
      return;
    }

    assert(() {
      if (_injectors.containsKey(T)) {
        printDebug(
            'Injector already contains type: ${T.toString()}. Injection of this type will be overriden.');
      }
      return true;
    }());

    _injectors[T] = (item, args) => inject(item, args);
  }

  @override
  void inject<T>(dynamic item, dynamic args) {
    final injector = findInjector<T>(item.runtimeType);

    if (injector != null) {
      injector(item, args);
    }
  }

  InitInjection? findInjector<T>([Type? type]) {
    if (T != dynamic && _injectors.containsKey(T)) {
      return _injectors[T];
    }

    if (type != null && _injectors.containsKey(type)) {
      return _injectors[type];
    }

    if (T != dynamic) {
      final key = _injectors.keys
          .firstWhere((item) => item.runtimeType is T, orElse: () => dynamic);

      if (key != dynamic) {
        return _injectors[key];
      }
    }

    return _other;
  }

  BaseInjector combine(BaseInjector other) => BaseInjector(
        injectors: {
          ..._injectors,
          ...other._injectors,
        },
        other: _other ?? other._other,
      );

  @override
  void dispose() {
    _injectors.clear();
    _other = null;
  }
}
