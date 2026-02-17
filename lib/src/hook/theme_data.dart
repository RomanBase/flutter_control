part of flutter_control;

/// Extension hook on [CoreContext] to provide easy access to the current [ThemeData].
extension ThemeDataHook on CoreContext {
  /// Returns the current [ThemeData] from the context.
  ///
  /// This hook uses [LazyHook] to cache the `ThemeData` and automatically
  /// invalidates it when dependencies change, ensuring the theme is always up-to-date.
  ThemeData get theme =>
      use<_ThemeDataHook>(value: () => _ThemeDataHook()).get(this);
}

class _ThemeDataHook with LazyHook<ThemeData> {
  @override
  ThemeData init(CoreContext context) => Theme.of(context);

  @override
  void onDependencyChanged(CoreContext context) => invalidate();
}
