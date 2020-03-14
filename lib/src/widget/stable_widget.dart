import 'package:flutter_control/core.dart';

class StableWidget extends StatefulWidget {
  final WidgetBuilder builder;
  final bool forceOverride;

  StableWidget({
    Key key,
    @required this.builder,
    this.forceOverride: false,
  }) : super(key: key);

  @override
  _StableWidgetState createState() => _StableWidgetState();
}

class _StableWidgetState extends State<StableWidget> {
  final holder = InitHolder<Widget>();

  @override
  Widget build(BuildContext context) {
    if (holder.isDirty || widget.forceOverride) {
      holder.set(builder: () => widget.builder(context), override: true);
    }

    return holder.get();
  }
}
