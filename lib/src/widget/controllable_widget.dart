import 'package:flutter_control/core.dart';

/// Experimental version, this Widget and how works is subject of change.
/// Currently supports [ActionControl], [FieldControl], [Listenable] and List of these objects.
abstract class ControllableWidget<T> extends CoreWidget {
  final T control;

  dynamic get value => (holder.state as _ControllableState?)?._value;

  ControllableWidget(
    this.control, {
    Key? key,
  })  : assert(control != null),
        super(key: key);

  @override
  void onInit(Map args) {
    super.onInit(args);

    if (control is ControlModel) {
      (control as ControlModel).register(this);
    }
  }

  @override
  State<StatefulWidget> createState() => _ControllableState<T>();

  Widget build(BuildContext context);
}

/// State of [ControllableWidget].
/// Simply wraps [ControlBuilder] or [ControlBuilderGroup] based on [ControllableWidget.control].
class _ControllableState<T> extends CoreState<ControllableWidget<T>> {
  dynamic _value;

  @override
  Widget build(BuildContext context) {
    final T _control = widget.control;

    if (_control is List) {
      return ControlBuilderGroup(
        controls: _control,
        builder: (context, values) {
          _value = values;
          return widget.build(context);
        },
      );
    } else {
      return ControlBuilder<dynamic>(
        control: _control,
        builder: (context, value) {
          _value = value;
          return widget.build(context);
        },
      );
    }
  }
}
