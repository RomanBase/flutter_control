import 'package:flutter_control/core.dart';

class CaseWidget<T> extends StatefulWidget {
  final dynamic activeCase;
  final Map<T, WidgetBuilder> builders;
  final dynamic args;
  final Widget placeholder;
  final CrossTransition transitionIn;
  final CrossTransition transitionOut;
  final Map<T, CrossTransition> caseTransition;

  const CaseWidget({
    Key key,
    @required this.activeCase,
    @required this.builders,
    this.args,
    this.placeholder,
    this.transitionIn,
    this.transitionOut,
    this.caseTransition,
  }) : super(key: key);

  @override
  _CaseWidgetState createState() => _CaseWidgetState();

  CrossTransition get activeTransitionIn {
    if (caseTransition != null && caseTransition.containsKey(activeCase)) {
      return caseTransition[activeCase];
    }

    return transitionIn;
  }
}

class _CaseWidgetState extends State<CaseWidget> {
  final control = TransitionControl()
    ..autoCrossIn() // cross automatically
    ..progress = 1.0; // start at first case

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

    builders = widget.builders;

    if (widget.activeCase != oldWidget.activeCase) {
      setState(() {
        control.progress = 0.0;
        _updateInitializer();
      });
    } else {
      setState(() {
        control.progress = 1.0; //ensure to stay on current case
        //TODO: solve this
        //_updateCurrentInitializer();
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

    if (oldInitializer == null) {
      oldInitializer = WidgetInitializer.of((_) => _placeholder());
      oldInitializer.key = GlobalKey();
    }
  }

  void _updateCurrentInitializer() {
    if (currentInitializer != null && widget.activeCase != null && builders.containsKey(widget.activeCase)) {
      final builder = builders[widget.activeCase];
      final origin = currentInitializer;

      currentInitializer = WidgetInitializer.of(builder);
      currentInitializer.key = origin.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TransitionHolder(
      control: control,
      args: widget.args,
      firstWidget: oldInitializer,
      secondWidget: currentInitializer,
      transitionIn: widget.activeTransitionIn,
      transitionOut: widget.transitionOut,
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

  @override
  void dispose() {
    super.dispose();

    if (control.isInitialized) {
      control.dispose();
    }
  }
}
