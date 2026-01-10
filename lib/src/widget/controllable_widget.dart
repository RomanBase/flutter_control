part of flutter_control;

/// A widget that is controlled by an external object.
///
/// This widget automatically subscribes to the given [control] and rebuilds
/// its UI whenever the control notifies of a change.
///
/// The [control] can be a single observable object or a list of them.
abstract class ControllableWidget<T> extends CoreWidget {
  /// The control object that this widget listens to.
  final T control;

  const ControllableWidget({
    super.key,
    required this.control,
  }) : assert(control != null);

  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    if (control is ControlModel) {
      (control as ControlModel).mount(context);
    }
  }

  @override
  CoreState<CoreWidget> createState() => _ControllableState<T>();

  /// Builds the widget's UI. This method is called whenever the [control]
  /// notifies of a change.
  Widget build(CoreContext context);
}

class _ControllableState<T> extends CoreState<ControllableWidget<T>> {
  @override
  Widget build(BuildContext context) {
    final _control = widget.control;

    if (_control is List) {
      return ControlBuilderGroup(
        controls: _control,
        builder: (context, values) => widget.build(element),
      );
    } else {
      return ControlBuilder<dynamic>(
        control: _control,
        builder: (context, value) => widget.build(element),
      );
    }
  }
}
