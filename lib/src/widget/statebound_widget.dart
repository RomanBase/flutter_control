import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

/// Extended [CoreWidget] what subscribes to just one [Listenable] or [StateControl] - a mixin class typically used with [ControlModel] - [BaseControl] or [BaseModel].
/// And state of this Widget is controlled from outside by [StateControl.notifyState] or by [ChangeNotifier.notifyListeners].
/// Whenever state of [ControlState]/[ChangeNotifier] is changed, this Widget is rebuild.
abstract class StateboundWidget<T extends Listenable> extends CoreWidget
    with LocalizationProvider {
  /// Current [StateControl] that notifies Widget about changes.
  @protected
  final T control;

  /// Current value of [control].
  /// [StateControl] returns [value] of state -> [StateControl.state.value].
  /// [ValueListenable] returns it's [value].
  /// [fallbackState] value or 'null' is returned otherwise.
  @protected
  dynamic get state {
    if (control is ValueListenable) {
      return (control as ValueListenable).value;
    }

    if (control is StateControl) {
      return (control as StateControl).state.value;
    }

    return fallbackState?.call(control);
  }

  /// Function that returns fallback [value] of [state] when no-value [control] is used.
  final dynamic Function(T control) fallbackState;

  /// Widget that is controlled by [Listenable] or [StateControl].
  /// [control] - State to subscribe. Whenever state is changed, this Widget is rebuild.
  /// [args] - Initial arguments to store. Can be whatever - [Object], [Iterable], [Map] and also [ControlArgs]. This arguments will be passed to [control] if implements [Initializable].
  /// [fallbackState] - Builds fallback [value] of [state]. This value is used when no-value [control] is used (e.g. pure [Listenable]).
  StateboundWidget({
    Key key,
    @required this.control,
    dynamic args,
    this.fallbackState,
  }) : super(key: key, args: args);

  @override
  void onInit(Map args) {
    super.onInit(args);

    if (control is StateControl) {
      (control as StateControl).onStateInitialized();
    }
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
class _WidgetboundState<T extends Listenable>
    extends CoreState<StateboundWidget<T>> implements StateNotifier {
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
      } else if (control is Disposable) {
        (control as Disposable).dispose();
      }

      control = null;
    }

    widget.dispose();
  }
}
