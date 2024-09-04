part of flutter_control;

class ControlScope {
  final BuildContext context;

  const ControlScope._(this.context);

  /// [parent] should be [BuildContext], [State] or [CoreWidget]
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

  _ControlRootScope get root => _ControlRootScope();

  /// Tries to provide object from Widget Tree by given [T] and/or [key].
  /// [parent] should be [BuildContext], [State] or [CoreWidget]
  static T? provide<T>(dynamic parent, {dynamic key, dynamic args}) =>
      ControlScope.of(parent).get<T>(
        key: key,
        args: args,
      );

  T? get<T>({dynamic key, dynamic args}) => _get<T>(key: key, args: args);

  T? _get<T>({dynamic key, dynamic args, BuildContext? context}) {
    context ??= this.context;

    final state = context.findAncestorStateOfType<ControlState>();

    if (state == null) {
      return null;
    }

    final item = Control.resolve<T>(
      ControlArgs.of(state.controls).merge(state.args).data,
      key: key,
      args: args,
    );

    if (item != null) {
      return item;
    }

    return _get(key: key, args: args, context: state.context);
  }
}
