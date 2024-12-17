import 'package:flutter_control/control.dart';

mixin LazyHook<T> implements Disposable {
  dynamic key;

  T? _value;

  T init(CoreContext context);

  T get(CoreContext context) => _value ?? (_value = init(context));

  void onDependencyChanged(CoreContext context) {}

  @override
  void dispose() {}
}
