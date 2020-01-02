import 'package:flutter_control/core.dart';

class NotifierBuilder<T> extends StatefulWidget {
  final Listenable control;
  final ControlWidgetBuilder<T> builder;

  const NotifierBuilder({
    Key key,
    @required this.control,
    @required this.builder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NotifierBuilderState();

  Widget build(BuildContext context) {
    if (control is ValueNotifier) {
      return builder(context, (control as ValueNotifier).value);
    }

    return builder(context, control as T);
  }
}

class _NotifierBuilderState extends State<NotifierBuilder> {
  @override
  void initState() {
    super.initState();

    widget.control.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    super.dispose();

    widget.control.removeListener(_updateState);
  }
}
