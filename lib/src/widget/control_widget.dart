part of flutter_control;

abstract class BaseControlWidget extends CoreWidget {
  Widget build(BuildContext context);

  @override
  CoreState<CoreWidget> createState() => BaseControlState();

  const BaseControlWidget({
    super.key,
    super.initArgs,
  });
}

class BaseControlState extends CoreState<BaseControlWidget> {
  @override
  Widget build(BuildContext context) => widget.build(context);
}

/// [ControlWidget] with one main [ControlModel].
/// Required [ControlModel] is returned by [initControl] - override this functions if Model is not in [args] or [ControlFactory] can't return it.
///
/// {@macro control-widget}
abstract class SingleControlWidget<T extends ControlModel>
    extends _ControlWidgetBase {
  /// specific [key] under which is [ControlModel] stored in [ControlFactory].
  dynamic get factoryKey => null;

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
      final controls = context.args.getAll<ControlModel>();

      if (controls.length > 1 && controls.contains(control)) {
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
  T? initControl(CoreContext context) => context.getControl<T>(key: factoryKey);

  @override
  Widget rebuild(CoreContext context) =>
      build(context, (context.state as ControlState).controls![0] as T);

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

/// {@template control-widget}
/// [ControlWidget] maintains larger UI parts of App (Pages or complex Widgets). Widget is created with default [ControlState] to correctly reflect lifecycle of [Widget] to Models and Controls. So there is no need to create custom [State].
/// Widget will [init] all containing Models and pass arguments to them.
/// [ControlWidget] is 'immutable' so all logic parts (even UI logic and animations) must be handled outside. This helps truly separate all 'code' from pure UI (also helps to reuse this code).
///
/// This Widget comes with few [mixin] classes:
///   - [RouteControl] to abstract navigation and easily pass arguments and init other Pages.
///   - [TickerControl] and [SingleTickerControl] to create [Ticker] and provide access to [vsync]. Then use [ControlModel] with [TickerComponent] to get access to [TickerProvider].
///
/// Typically one or more [ControlModel] objects handles all logic for [ControlWidget]. This solution helps to separate even [Animation] from Business Logic and UI Widgets part.
/// And comes with [LocalizationProvider] to use [BaseLocalization] without standard delegate solution.
///
/// [ControlWidget] - Basic Widget with manual [ControlModel] initialization.
/// [SingleControlWidget] - Focused to single [ControlModel]. But still can handle multiple Controls.
/// [MountedControlWidget] - Automatically uses all [ControlModel]s passed to Widget.
///
/// Also check [ControllableWidget] an abstract Widget focused to build smaller Widgets controlled by [ObservableModel] and [BaseModel].
/// {@endtemplate}
abstract class _ControlWidgetBase extends CoreWidget {
  /// Checks [args] and returns all [ControlModel]s during [initControls] and these Models will be initialized by this Widget.
  /// By default set to 'false'.
  bool get autoMountControls => false;

  /// Focused to handle Pages or complex Widgets.
  /// [args] - Arguments passed to this Widget and also to [ControlModel]s.
  /// Check [SingleControlWidget] and [MountedControlWidget] to automatically handle input Controls.
  const _ControlWidgetBase({
    super.key,
    super.initArgs,
  });

  /// This is a place where to fill all required [ControlModel]s for this Widget.
  /// Called during Widget/State initialization phase.
  ///
  /// Dependency Injection possibilities:
  /// [holder.findControls] - Returns [ControlModel]s from 'constructor' and 'init' [args].
  /// [getControl] - Tries to find specific [ControlModel]. Looks up in current [stateNotifiers], [args] and dependency Store.
  /// [Control.get] - Returns object from [ControlFactory].
  /// [Control.init] - Initializes object via [ControlFactory].
  ///
  /// Returns [stateNotifiers] to init, subscribe and dispose with Widget.
  @protected
  List<ControlModel> initControls(CoreContext context) =>
      autoMountControls ? context.args.getAll<ControlModel>() : [];

  @override
  CoreState createState() => ControlState();

  /// Called during [State] initialization.
  /// Widget will subscribe to all [stateNotifiers].
  /// Typically now need to override - check [onInit] and [onUpdate] functions.
  @protected
  @mustCallSuper
  void onInitRuntime(ControlState state) {
    if (state.controls == null || state.controls!.isEmpty) {
      printDebug('no controls found - onInitState');
      return;
    }

    state.controls?.remove(null);
    state.controls?.forEach((control) {
      control.init(state.args.data);
      control.register(state);

      if (control is ObservableComponent) {
        state.element.registerStateNotifier(control);
      }
    });
  }

  /// Callback from [State] when state is notified.
  @protected
  void onStateChanged(dynamic state) {}

  @protected
  Widget rebuild(CoreContext context);

  /// Disposes and removes all [stateNotifiers].
  /// Check [DisposeHandler] for different dispose strategies.
  void dispose() {
    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// [State] of [ControlWidget]
class ControlState<U extends _ControlWidgetBase> extends CoreState<U> {
  List<ControlModel>? controls;

  @override
  void initRuntime() {
    super.initRuntime();

    controls = widget.initControls(element);

    element.args.set(controls!.toSet());

    controls!.forEach((control) {
      if (control is ReferenceCounter) {
        (control as ReferenceCounter).addReference(this);
      }
    });

    widget.onInitRuntime(this);
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

    if (controls != null) {
      controls!.forEach((control) {
        control.requestDispose(this);
      });
      controls!.clear();
      controls = null;
    }

    widget.dispose();
  }
}
