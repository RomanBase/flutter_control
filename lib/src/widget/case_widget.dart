import 'package:flutter_control/core.dart';

class CaseWidget<T> extends StatefulWidget {
  final dynamic activeCase;
  final Map<T, WidgetBuilder> builders;
  final dynamic args;
  final Widget placeholder;
  final CrossTransition transition;

  const CaseWidget({
    Key key,
    @required this.activeCase,
    @required this.builders,
    this.args,
    this.placeholder,
    this.transition,
  }) : super(key: key);

  @override
  _CaseWidgetState createState() => _CaseWidgetState();
}

class _CaseWidgetState extends State<CaseWidget> {
  final control = TransitionControl()..autoCrossIn(from: 0.0);

  WidgetInitializer oldInitializer;
  WidgetInitializer currentInitializer;

  Map builders;

  @override
  void initState() {
    super.initState();

    builders = widget.builders;
    _updateInitializer();
  }

  @override
  void didUpdateWidget(CaseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activeCase != oldWidget.activeCase) {
      setState(() {
        _updateInitializer();
      });
    }
  }

  void _updateInitializer() {
    oldInitializer = currentInitializer;

    if (widget.activeCase != null && builders.containsKey(widget.activeCase)) {
      final builder = builders[widget.activeCase];

      currentInitializer = WidgetInitializer.of(builder);
    } else {
      currentInitializer = WidgetInitializer.of((_) => _placeholder());
    }

    currentInitializer.key = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    if (oldInitializer != null && currentInitializer != null) {
      return TransitionInitHolder(
        control: control,
        firstWidget: oldInitializer,
        secondWidget: currentInitializer,
        transitionIn: widget.transition,
        args: widget.args,
      );
    }

    return KeyedSubtree(
      key: currentInitializer.key,
      child: currentInitializer.getWidget(context, args: widget.args),
    );
  }

  Widget _placeholder() {
    if (widget.placeholder != null) {
      return widget.placeholder;
    }

    if (widget.activeCase == null) {
      return Container();
    }

    return Container(
      color: Colors.red,
      child: Center(
        child: Text(widget.activeCase.toString()),
      ),
    );
  }
}
