part of flutter_control;

mixin LazyHook<T> implements Disposable {
  dynamic key;

  T? _value;

  T init(CoreContext context);

  T get(CoreContext context) => _value ?? (_value = init(context));

  void onDependencyChanged(CoreContext context) {}

  void invalidate() => _value = null;

  @override
  void dispose() {}
}
