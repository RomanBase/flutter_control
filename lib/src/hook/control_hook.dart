part of flutter_control;

/// A mixin to implement a lazy-initialized object (a "hook") that is tied to
/// the lifecycle of a [CoreContext]. The object is created only when first accessed.
mixin LazyHook<T> implements Disposable {
  /// An optional key to uniquely identify the hook if needed.
  dynamic key;

  /// The cached value of the hook.
  T? _value;

  /// Initializes the value of the hook. This is called only once when the
  /// value is first accessed.
  T init(CoreContext context);

  /// Gets the value of the hook. If the value has not been initialized yet,
  /// it calls [init] to create it.
  T get(CoreContext context) => _value ?? (_value = init(context));

  /// Called when the dependencies of the host widget change.
  /// Subclasses can override this to invalidate the hook and force re-initialization.
  void onDependencyChanged(CoreContext context) {}

  /// Invalidates the cached value, forcing [init] to be called on the next access.
  void invalidate() => _value = null;

  @override
  void dispose() {}
}
