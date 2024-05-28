part of flutter_control;

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
      (control as ControlModel).mount(context);
    }
  }

  @override
  CoreState<CoreWidget> createState() => _ControllableState<T>();

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
