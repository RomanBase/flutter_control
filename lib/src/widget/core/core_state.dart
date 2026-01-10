part of flutter_control;

/// The base [State] object for a [CoreWidget].
///
/// It is intrinsically linked to a [CoreContext] (its [Element]), which handles
/// dependency management and the lifecycle of registered resources. This state's
/// primary roles are to trigger rebuilds via [notifyState] and to host the
/// standard [State] lifecycle callbacks, which are then proxied to the
/// [CoreContext] and [CoreWidget].
abstract class CoreState<T extends CoreWidget> extends State<T> {
  /// A typed getter for the widget's context, which is always a [CoreContext].
  CoreContext get element => context as CoreContext;

  /// A shortcut to access the arguments and dependencies stored in the [CoreContext].
  ControlArgs get args => element.args;

  /// Checks if the element is marked as dirty and needs to be rebuilt.
  bool get isDirty => element.dirty;

  /// A callback from [CoreContext], indicating that the state has been fully
  /// initialized and all dependencies are ready.
  ///
  /// This is the recommended place for initialization logic that requires a
  /// fully usable [BuildContext].
  void onInit() {}

  /// Schedules a rebuild of the widget.
  ///
  /// To prevent unnecessary rebuilds, it only calls `setState` if the widget
  /// is mounted and not already marked as dirty.
  void notifyState() {
    if (mounted && !isDirty) {
      setState(() {});
    }
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();

    element.onDependencyChanged();
  }

  @override
  @mustCallSuper
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.onUpdate(element, oldWidget);
  }

  @override
  @mustCallSuper
  void dispose() {
    widget.onDispose();
    element.onDispose();

    super.dispose();
  }
}
