part of flutter_control;

/// Base abstract [State] of [CoreWidget].
/// Dependency changes and lifecycle of resources are controlled by [CoreContext]. But this State still notifies Element.
abstract class CoreState<T extends CoreWidget> extends State<T> {
  /// Retype [context] of this state to [CoreContext].
  /// [CoreWidget] comes with [CoreContext] by default.
  CoreContext get element => context as CoreContext;

  /// Reference to [CoreContext.args].
  ControlArgs get args => element.args;

  /// Checks if [Element] is 'dirty' and needs rebuild.
  bool get isDirty => element.dirty;

  /// Callback, controlled by [CoreContext].
  /// State is ready with all dependencies and [context] is fully usable without restrictions.
  ///
  /// Use [initState] for early initialization.
  void onInit() {}

  /// Notify this state to schedule rebuild.
  /// [setState] is called only if [context] is ready and Widget is not scheduled for rebuild.
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
