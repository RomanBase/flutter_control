import 'package:flutter_control/control.dart';

mixin LazyHook<T> implements Disposable {
  dynamic key;

  late T hookValue;

  T init(CoreContext context);

  void onDependencyChanged(CoreContext context) {}

  @override
  void dispose() {}
}
