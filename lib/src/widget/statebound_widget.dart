import 'package:flutter_control/core.dart';

/// Extended [CoreWidget] what subscribes to just one [StateControl] - a mixin class typically used with [ControlModel] - [BaseControl] or [BaseModel].
/// And state of this Widget is controlled from outside by [StateControl.notifyState].
/// Whenever state of [ControlState] is changed, this Widget is rebuild.
abstract class StateboundWidget<T extends StateControl> extends CoreWidget with LocalizationProvider {
  /// Current [StateControl] that notifies Widget about changes.
  @protected
  final T control;

  /// Current state [value] of [StateControl]
  @protected
  dynamic get state => control.state.value;

  /// Widget that is controlled by [StateControl] - a mixin class typically used with [ControlModel] - [BaseControl] or [BaseModel]..
  /// [control] - State to subscribe. Whenever state is changed, this Widget is rebuild.
  /// [args] - Initial arguments to store. Can be whatever - [Object], [Iterable], [Map] and also [ControlArgs]. This arguments will be passed to [control] if implements [Initializable].
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

/// [State] of [StateboundWidget].
/// Handles [StateControl] and rebuilds Widget whenever state is notified.
class _WidgetboundState<T extends StateControl> extends CoreState<StateboundWidget<T>> implements StateNotifier {
  /// Current [ControlState].
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
