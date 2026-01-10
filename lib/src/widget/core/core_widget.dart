part of flutter_control;

/// The base [StatefulWidget] for the Control framework.
///
/// It creates a [CoreContext] (its [Element]), which is the heart of the
/// framework's state management and dependency injection system. All other
/// control widgets ([ControlWidget], [SingleControlWidget], etc.) extend from this.
///
/// See also:
///  - [CoreState], the state object for this widget.
///  - [CoreContext], the element that manages the widget's lifecycle and dependencies.
abstract class CoreWidget extends StatefulWidget {
  /// A map of initial arguments to be passed to the [CoreContext].
  ///
  /// These arguments can be retrieved within the widget's lifecycle using
  /// `context.get<T>()` or `context.args`.
  final Map initArgs;

  /// Creates a [CoreWidget].
  const CoreWidget({
    super.key,
    this.initArgs = const {},
  });

  @override
  CoreContext createElement() => CoreContext(this);

  @override
  CoreState createState();

  /// A preliminary initialization method called by the [CoreContext].
  /// This is a good place for mixins to hook into the initialization process.
  @protected
  void init(CoreContext context) {}

  /// Called once when the state is fully initialized and the context is available.
  ///
  /// This is the recommended place to register dependencies, state notifiers,
  /// and other resources that the widget will need.
  @protected
  @mustCallSuper
  void onInit(Map args, CoreContext context) {}

  /// Called when the widget is updated with new configuration.
  /// See [State.didUpdateWidget] for more information.
  @protected
  void onUpdate(CoreContext context, CoreWidget oldWidget) {}

  /// Called when a dependency of this widget changes.
  /// See [State.didChangeDependencies] for more information.
  @protected
  void onDependencyChanged(CoreContext context) {}

  /// Called when the widget is being disposed.
  @protected
  @mustCallSuper
  void onDispose() {}
}
