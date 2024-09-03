part of flutter_control;

//TODO: make it Stateless
abstract class BaseControlWidget extends CoreWidget {
  const BaseControlWidget({
    super.key,
    super.initArgs,
  });

  @override
  CoreState<CoreWidget> createState() => BaseControlState();

  Widget build(CoreContext context);
}

class BaseControlState extends CoreState<BaseControlWidget> {
  @override
  Widget build(BuildContext context) => widget.build(element);
}

abstract class SingleControlWidget<T extends ControlModel>
    extends _ControlWidgetBase {
  /// If given [args] contains [ControlModel] of requested [Type], it will be used as [control], otherwise [Control.get] will provide requested [ControlModel].
  const SingleControlWidget({
    super.key,
    super.initArgs,
  });

  @override
  List<ControlModel> initControls(CoreContext context) {
    final control = initControl(context);

    if (control == null) {
      throw 'NULL Control - $this';
    }

    if (autoMountControls) {
      final controls = super.initControls(context);

      if (controls.contains(control)) {
        controls.remove(control);
      }

      controls.insert(0, control);

      return controls;
    }

    return [control];
  }

  /// Tries to find or construct instance of requested [Type].
  /// If init [args] contains [ControlModel] of requested [Type], it will be used as [control], otherwise [Control.get] will provide requested [ControlModel].
  /// Check [initControls] for more dependency possibilities.
  /// Returns [ControlModel] of given [Type].
  @protected
  T? initControl(CoreContext context) => context.getControl<T>();

  @override
  Widget rebuild(CoreContext context) =>
      build(context, (context.state as ControlState).controls[0] as T);

  Widget build(CoreContext context, T control);
}

abstract class ControlWidget extends _ControlWidgetBase {
  const ControlWidget({
    super.key,
    super.initArgs,
  });

  @override
  Widget rebuild(CoreContext context) => build(context);

  Widget build(CoreContext context);
}

/// Focused to handle Pages and complex Widgets.
abstract class _ControlWidgetBase extends CoreWidget {
  /// Checks [args] and returns all [ControlModel]s during [initControls] and these Models will be initialized by this Widget.
  /// By default set to 'false'.
  bool get autoMountControls => false;

  const _ControlWidgetBase({
    super.key,
    super.initArgs,
  });

  @override
  CoreState createState() => ControlState();

  /// This is a place where to fill all required [ControlModel]s for this Widget.
  /// Called during Widget/State initialization phase.
  @protected
  List<ControlModel> initControls(CoreContext context) {
    if (this is Dependency) {
      return [
        ...(this as Dependency)
            .getControlDependencies()
            .where((item) => item is ControlModel),
        if (autoMountControls) ...context.args.getAll<ControlModel>(),
      ];
    }

    return autoMountControls ? context.args.getAll<ControlModel>() : [];
  }

  @protected
  void onInitState(ControlState state) {}

  @protected
  Widget rebuild(CoreContext context);

  /// Callback from [State] when state is notified.
  @protected
  void onStateChanged(dynamic state) {}

  @override
  void onDispose() {
    super.onDispose();

    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// [State] of [ControlWidget]
class ControlState<U extends _ControlWidgetBase> extends CoreState<U> {
  late List<ControlModel> controls;

  @override
  void onInit() {
    super.onInit();

    controls = widget.initControls(element);

    element.args.set(controls.toSet());

    controls.forEach((control) {
      if (control is ReferenceCounter) {
        (control as ReferenceCounter).addReference(this);
      }
    });

    if (controls.isEmpty) {
      printDebug('no controls found - onInitState');
      return;
    }

    controls.remove(null);
    controls.forEach((control) {
      control.init(element.args.data);
      control.mount(this);

      if (control is ObservableComponent) {
        element.registerStateNotifier(control);
      }
    });

    widget.onInitState(this);
  }

  @override
  void notifyState([dynamic state]) {
    if (mounted) {
      setState(() {
        widget.onStateChanged(state);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.rebuild(element);

  /// Disposes and removes all [controls].
  /// Controller can prevent disposing [BaseControl.preventDispose].
  /// Then disposes Widget.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();

    if (controls.isNotEmpty) {
      controls.forEach((control) {
        control.requestDispose(this);
      });
      controls.clear();
    }
  }
}
