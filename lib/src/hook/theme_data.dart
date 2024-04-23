part of flutter_control;

extension ThemeDataHook on CoreContext {
  ThemeData get theme =>
      use<_ThemeDataHook>(value: () => _ThemeDataHook())!.hookValue;
}

class _ThemeDataHook with LazyHook<ThemeData> {
  @override
  ThemeData init(CoreContext context) => Theme.of(context);

  @override
  void onDependencyChanged(CoreContext context) {
    context.set<_ThemeDataHook>(value: null);
  }
}
