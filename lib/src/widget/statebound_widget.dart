import 'package:flutter_control/core.dart';

abstract class StateboundWidget<T extends StateControl> extends CoreWidget with LocalizationProvider implements Initializable, Disposable {
  @protected
  final T control;

  @protected
  dynamic get state => control.state.value;

  StateboundWidget({
    Key key,
    @required this.control,
    dynamic args,
  }) : super(key: key, args: args);

  @override
  void onInit(Map args) {
    super.onInit(args);

    control.onStateInitialized();
  }

  @override
  State<StatefulWidget> createState() => _WidgetboundState<T>();

  @protected
  Widget build(BuildContext context);

  @override
  void dispose() {}
}

class _WidgetboundState<T extends StateControl> extends CoreState<StateboundWidget<T>> {
  T get control => widget.control;

  @override
  void initState() {
    super.initState();

    widget.holder.init(this);
    control.init(widget.holder.args);

    if (widget is TickerProvider && control is TickerComponent) {
      (control as TickerComponent).provideTicker(widget as TickerProvider);
    }

    control.addListener(_updateState);

    if (control is ReferenceCounter) {
      (control as ReferenceCounter).addReference(this);
    }
  }

  void _updateState() => setState(() {});

  @override
  void didUpdateWidget(StateboundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.control != widget.control) {
      oldWidget.control.removeListener(_updateState);
      widget.control.addListener(_updateState);
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    super.dispose();

    widget.dispose();

    control.removeListener(_updateState);

    if (control is DisposeHandler) {
      (control as DisposeHandler).requestDispose(this);
    } else {
      control.dispose();
    }
  }
}
