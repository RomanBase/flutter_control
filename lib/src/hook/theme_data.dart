part of '../../control.dart';

/// Extension hook on [CoreContext] to provide easy access to the current [ThemeData].
extension ThemeDataHook on BuildContext {
  /// Returns the current [ThemeData] from the context.
  ///
  /// This hook uses [LazyHook] to cache the `ThemeData` and automatically
  /// invalidates it when dependencies change, ensuring the theme is always up-to-date.
  ThemeData get theme => this is CoreContext
      ? use<_ThemeDataHook>(value: () => _ThemeDataHook())
          .get(this as CoreContext)
      : Theme.of(this);
}

class _ThemeDataHook with LazyHook<ThemeData> {
  @override
  ThemeData init(CoreContext context) => Theme.of(context);

  @override
  void onDependencyChanged(CoreContext context) => invalidate();
}
