import 'package:flutter_control/core.dart';

class ControlScope {
  final BuildContext? context;

  const ControlScope._(this.context);

  static ControlRootScope get root => ControlRootScope.main();

  factory ControlScope.of([dynamic parent]) {
    BuildContext? context;

    if (parent is BuildContext) {
      context = parent;
    }

    if (context == null) {
      if (parent is CoreWidget) {
        context = parent.context;
      } else if (parent is State) {
        context = parent.context;
      }
    }

    return ControlScope._(context ?? root.context);
  }

  static T? provide<T>(dynamic parent, {dynamic key, dynamic args}) =>
      ControlScope.of(parent).get(
        key: key,
        args: args,
      );

  T? _get<T>({dynamic key, dynamic args, BuildContext? context}) {
    context ??= this.context;

    if (context == null) {
      return null;
    }

    final state = context.findAncestorStateOfType<ControlState>();

    if (state == null) {
      return Control.get<T>(key: key, args: args);
    }

    return Control.resolve<T>(
          ControlArgs(state.controls).combineWith(state.args).data,
          key: key,
          args: args,
        ) ??
        _get(key: key, args: args, context: state.context);
  }

  T? get<T>({dynamic key, dynamic args}) => _get<T>(key: key, args: args);
}
