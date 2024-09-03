part of flutter_control;

/// [State] of [CoreWidget].
abstract class CoreState<T extends CoreWidget> extends State<T> {
  CoreContext get element => context as CoreContext;

  ControlArgs get args => element.args;

  /// Checks if [Element] is 'dirty' and needs rebuild.
  bool get isDirty => element.dirty;

  void onInit() {}

  void notifyState() {
    if (!isDirty) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    element.onDependencyChanged();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.onUpdate(oldWidget);
  }

  @override
  void dispose() {
    widget.onDispose();
    element.onDispose();

    super.dispose();
  }
}
