part of flutter_control;

class ControlScope {
  final BuildContext context;

  const ControlScope._(this.context);

  /// [parent] should be [BuildContext], [Element] or [State]
  factory ControlScope.of([dynamic parent]) {
    BuildContext? context;

    if (parent is BuildContext) {
      context = parent;
    } else if (parent is State) {
      context = parent.context;
    } else if (parent is Element) {
      context = parent;
    }

    assert(context != null);

    return ControlScope._(context!);
  }

  static _ControlRootScope get root => _ControlRootScope();

  T? get<T>({dynamic key, dynamic args, ControlFactory? factory}) =>
      _get<T>(factory, key: key, args: args);

  T? _get<T>(ControlFactory? factory,
      {dynamic key, dynamic args, BuildContext? context}) {
    context ??= this.context;

    final state = context.findAncestorStateOfType<CoreState>();

    if (state == null) {
      if (factory != null) {
        return factory.get<T>(key: key, args: args);
      }

      return null;
    }

    if (state.args.containsKey(key ?? T)) {
      return state.args.get<T>(key: key);
    }

    if (state is ControlState) {
      final controls = ControlArgs.of(state.controls);
      if (controls.containsKey(key ?? T)) {
        return controls[key ?? T];
      }
    }

    return _get(factory, key: key, args: args, context: state.context);
  }
}
