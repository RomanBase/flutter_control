import 'package:flutter_control/core.dart';

/// Experimental version, this Widget and how works is subject of change.
/// Currently supports [ActionControl], [FieldControl], [Listenable] and List of these objects.
abstract class ControllableWidget<T> extends CoreWidget {
  final T control;

  dynamic get value => (holder.state as _ControlableState)?._value;

  ControllableWidget(
    this.control, {
    Key key,
  })  : assert(control != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _ControlableState<T>();

  Widget build(BuildContext context);
}

/// State of [ControllableWidget].
/// Simply wraps [ControlBuilder] or [ControlBuilderGroup] based on [ControllableWidget.control].
class _ControlableState<T> extends CoreState<ControllableWidget<T>> {
  dynamic _value;

  @override
  Widget build(BuildContext context) {
    final _control = widget.control;

    if (_control is List) {
      return ControlBuilderGroup(
        controls: _control,
        builder: (context, values) {
          _value = values;
          return widget.build(context);
        },
      );
    } else {
      return ControlBuilder(
        control: _control,
        nullOk: true,
        builder: (context, value) {
          _value = value;
          return widget.build(context);
        },
      );
    }
  }
}
