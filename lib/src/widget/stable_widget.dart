import 'package:flutter_control/core.dart';

class StableWidget extends StatefulWidget {
  final WidgetBuilder builder;
  final bool forceOverride;
  final bool localize;

  StableWidget({
    Key key,
    @required this.builder,
    this.forceOverride: false,
    this.localize: true,
  }) : super(key: key);

  @override
  _StableWidgetState createState() => _StableWidgetState();
}

class _StableWidgetState extends State<StableWidget> {
  final holder = InitHolder<Widget>();

  BroadcastSubscription _sub;

  @override
  void initState() {
    super.initState();

    if (widget.localize) {
      _sub = BroadcastProvider.subscribe<LocalizationArgs>(BaseLocalization, (args) {
        if (args.changed) {
          setState(() {
            holder.setDirty();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (holder.isDirty || widget.forceOverride) {
      holder.set(builder: () => widget.builder(context), override: true);
    }

    return holder.get();
  }

  @override
  void dispose() {
    super.dispose();

    _sub?.dispose();
    _sub = null;
  }
}
