part of flutter_control;

/// Provides access to the control framework's dependency injection system
/// within a specific [BuildContext]. It allows retrieving dependencies from the
/// nearest [CoreState] ancestor in the widget tree.
class ControlScope {
  /// The build context from which to start the search for dependencies.
  final BuildContext context;

  const ControlScope._(this.context);

  /// Creates a [ControlScope] for a given [parent] context.
  ///
  /// [parent] should be a [BuildContext], [Element], or [State].
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

  /// Accesses the root scope of the application for managing global state.
  static _ControlRootScope get root => _ControlRootScope();

  /// Retrieves a dependency of type [T] from the widget tree, searching upwards
  /// from the current [context].
  ///
  /// [key] An optional key to identify a specific instance of the dependency.
  /// [args] Optional arguments to pass if the dependency needs to be created.
  /// [factory] An optional [ControlFactory] to use for dependency creation.
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
