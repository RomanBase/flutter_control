import 'package:flutter_control/core.dart';

class NotifierBuilder<T> extends StatefulWidget {
  final Listenable model;
  final ControlWidgetBuilder<T> builder;

  const NotifierBuilder({
    Key key,
    @required this.model,
    @required this.builder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NotifierBuilderState();

  Widget build(BuildContext context) {
    if (model is ValueNotifier) {
      return builder(context, (model as ValueNotifier).value);
    }

    return builder(context, model as T);
  }
}

class _NotifierBuilderState extends State<NotifierBuilder> {
  @override
  void initState() {
    super.initState();

    widget.model.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    super.dispose();

    widget.model.removeListener(_updateState);
  }
}
