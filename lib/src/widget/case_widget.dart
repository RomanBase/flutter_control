import 'package:flutter_control/core.dart';

class CaseWidget extends StatefulWidget {
  final dynamic activeCase;
  final Map<dynamic, WidgetBuilder> builders;
  final dynamic args;
  final Widget placeholder;

  const CaseWidget({
    Key key,
    @required this.activeCase,
    @required this.builders,
    this.args,
    this.placeholder,
  }) : super(key: key);

  @override
  _CaseWidgetState createState() => _CaseWidgetState();
}

class _CaseWidgetState extends State<CaseWidget> {
  WidgetInitializer initializer;

  @override
  void initState() {
    super.initState();

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
    if (widget.activeCase != null && widget.builders.containsKey(widget.activeCase)) {
      final builder = widget.builders[widget.activeCase];

      initializer = WidgetInitializer.of(builder);
    } else {
      initializer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (initializer != null) {
      return initializer.getWidget(context, args: widget.args);
    }

    return widget.placeholder ?? Container();
  }
}
