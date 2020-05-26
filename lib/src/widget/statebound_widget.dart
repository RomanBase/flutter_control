import 'package:flutter_control/core.dart';

abstract class StateboundWidget<T extends StateControl> extends CoreWidget with LocalizationProvider {
  @protected
  final T control;

  /// Current State value of Control
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
  _WidgetboundState<T> createState() => _WidgetboundState<T>();

  @protected
  Widget build(BuildContext context);

  @override
  void dispose() {
    super.dispose();
  }
}

class _WidgetboundState<T extends StateControl> extends CoreState<StateboundWidget<T>> implements StateNotifier {
  T control;

  @override
  void initState() {
    super.initState();

    _setControl(widget.control);

    widget.holder.init(this);

    if (control is Initializable) {
      (control as Initializable).init(widget.holder.args);
    }
  }

  @override
  void notifyState([state]) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(StateboundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.control != control) {
      control?.removeListener(notifyState);
      _setControl(widget.control);
    }
  }

  void _setControl(T value) {
    assert(value != null);

    control = value;
    control.addListener(notifyState);

    if (widget is TickerProvider && control is TickerComponent) {
      (control as TickerComponent).provideTicker(widget as TickerProvider);
    }

    control.addListener(notifyState);

    if (control is ReferenceCounter) {
      (control as ReferenceCounter).addReference(this);
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    super.dispose();

    if (control != null) {
      control.removeListener(notifyState);

      if (control is DisposeHandler) {
        (control as DisposeHandler).requestDispose(this);
      } else {
        control.dispose();
      }

      control = null;
    }

    widget.dispose();
  }
}
