import 'package:flutter_control/core.dart';

abstract class StateboundWidget<T extends StateControl> extends CoreWidget with LocalizationProvider implements Initializable, Disposable {
  _WidgetboundState get _state => holder.state;

  @protected
  T get control => _state?.control;

  @protected
  dynamic get state => control?.state?.value;

  StateboundWidget({
    Key key,
    dynamic args,
  }) : super(key: key) {
    holder.set(args);
  }

  @override
  void init(Map args) {
    holder.set(args);
  }

  @protected
  T initControl() {
    T item = holder.get<T>();

    if (item == null) {
      item = Control.get<T>(args: holder.args);
    }

    return item;
  }

  @override
  State<StatefulWidget> createState() => _WidgetboundState<T>();

  @protected
  Widget build(BuildContext context);

  @override
  void dispose() {}
}

class _WidgetboundState<T extends StateControl> extends CoreState<StateboundWidget<T>> {
  T control;

  @override
  void initState() {
    super.initState();

    widget.holder.init(this);

    control = widget.initControl();

    assert(control != null);

    control.init(widget.holder.args);

    if (widget is TickerProvider && control is TickerComponent) {
      (control as TickerComponent).provideTicker(widget as TickerProvider);
    }

    control.addListener(_updateState);
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

    control.removeListener(_updateState);
    widget.dispose();
  }
}
