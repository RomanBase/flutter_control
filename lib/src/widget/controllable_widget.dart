part of flutter_control;

/// Experimental version, this Widget and how works is subject of change.
/// Currently supports [ActionControl], [FieldControl], [Listenable] and List of these objects.
abstract class ControllableWidget<T> extends CoreWidget {
  final T control;

  const ControllableWidget({
    super.key,
    required this.control,
  }) : assert(control != null);

  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    if (control is ControlModel) {
      (control as ControlModel).register(this);
    }
  }

  @override
  CoreState<CoreWidget> createState() => _ControllableState<T>();

  Widget build(BuildContext context);
}

/// State of [ControllableWidget].
/// Simply wraps [ControlBuilder] or [ControlBuilderGroup] based on [ControllableWidget.control].
class _ControllableState<T> extends CoreState<ControllableWidget<T>> {
  @override
  Widget build(BuildContext context) {
    final T _control = widget.control;

    if (_control is List) {
      return ControlBuilderGroup(
        controls: _control,
        builder: (context, values) {
          return widget.build(context);
        },
      );
    } else {
      return ControlBuilder(
        control: _control,
        builder: (context, value) {
          return widget.build(context);
        },
        noData: (context) {
          return widget.build(context);
        },
      );
    }
  }
}
