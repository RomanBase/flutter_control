part of flutter_control;

mixin ContextComponent on ControlModel {
  CoreContext? context;

  @override
  void mount(object) {
    super.mount(object);

    if (object is CoreState) {
      context = object.element;
    }

    if (object is CoreContext) {
      context = object;
    }
  }
}

extension ContextRootExt on BuildContext {
  RootContext get root => RootContext.of(this)!;
}

extension ContextScopeExt on CoreContext {
  ControlScope get scope => ControlScope.of(this);

  /// Returns [ControlModel] by given [T] or [key] from current UI Tree
  T? getScopeControl<T extends ControlModel?>({dynamic key, dynamic args}) =>
      scope.get<T>(key: key, args: args);
}
