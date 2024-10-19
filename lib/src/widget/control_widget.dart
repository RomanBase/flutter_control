part of flutter_control;

/// Entry Widget control state management with single [ControlModel].
/// Multiple observers and multiple state notifiers can request rebuild of this widget.
///
/// [onInit] is called right after initState and before build.
///  - [context] is here fully usable without restrictions.
///  - Best place to register state notifiers, hooks and other resources.
///
/// Retrieve these references with [CoreContext.get].
///
/// Check [InitProvider] and [LazyProvider] mixins to inject this Widget.
/// Check [OnLayout] mixin to process resources after view is adjusted.
abstract class BaseControlWidget extends CoreWidget {
  const BaseControlWidget({
    super.key,
    super.initArgs,
  });

  @override
  CoreState<CoreWidget> createState() => BaseControlState();

  /// Build actual Widget.
  /// Use [context] to work with references, dependencies, state management, routing, etc. Check [CoreContext] as underlying [Element] of this Widget.
  ///
  /// DO NOT call directly [register]/[registerStateNotifier] during build call - instead use [onInit] to register once.
  /// Within build method you can register state notifier with `context.use(.., stateNotifier = true)`;
  Widget build(CoreContext context);
}

class BaseControlState extends CoreState<BaseControlWidget> {
  @override
  Widget build(BuildContext context) => widget.build(element);
}

/// Entry Widget control state management with single [ControlModel].
/// Still multiple observers and multiple state notifiers can request rebuild of this widget.
/// If [T] is not found, then error occurs.
///
/// [onInit] is called right after initState and before build.
///  - [context] is here fully usable without restrictions.
///  - Best place to register state notifiers, hooks and other resources.
///
/// [initControl], [initControls] registers given [ControlModel]s to this Widget. Check [DisposeHandler] and [ReferenceCounter] to prevent early dispose of given Models.
/// Retrieve these references with [CoreContext.get].
///
/// Check [InitProvider] and [LazyProvider] mixins to inject this Widget.
/// Check [OnLayout] mixin to process resources after view is adjusted.
/// Check [BaseControlWidget] for lightweight implementation.
abstract class SingleControlWidget<T extends ControlModel>
    extends _ControlWidgetBase {
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
  /// If [CoreContext.args] contains [ControlModel] of requested [Type], it will be used as [control].
  /// Check [initControls] for more dependency possibilities.
  /// Returns [ControlModel] of given [Type].
  @protected
  T? initControl(CoreContext context) => Control.resolve<T>(context.args);

  @override
  Widget rebuild(CoreContext context) => build(context, context<T>()!);

  /// Build actual Widget.
  /// Use [context] to work with references, dependencies, state management, routing, etc. Check [CoreContext] as underlying [Element] of this Widget.
  ///
  /// DO NOT call directly [register]/[registerStateNotifier] during build call - instead use [onInit] to register once.
  /// Within build method you can register state notifier with `context.use(.., stateNotifier = true)`;
  Widget build(CoreContext context, T control);
}

/// Entry Widget control state management with single [ControlModel].
/// Multiple observers and multiple state notifiers can request rebuild of this widget.
///
/// [onInit] is called right after initState and before build.
///  - [context] is here fully usable without restrictions.
///  - Best place to register state notifiers, hooks and other resources.
///
/// [initControls] registers given [ControlModel]s to this Widget. Check [DisposeHandler] and [ReferenceCounter] to prevent early dispose of given Models.
/// Retrieve these references with [CoreContext.get].
///
/// Check [InitProvider] and [LazyProvider] mixins to inject this Widget.
/// Check [OnLayout] mixin to process resources after view is adjusted.
/// Check [BaseControlWidget] for lightweight implementation.
abstract class ControlWidget extends _ControlWidgetBase {
  const ControlWidget({
    super.key,
    super.initArgs,
  });

  @override
  Widget rebuild(CoreContext context) => build(context);

  /// Build actual Widget.
  /// Use [context] to work with references, dependencies, state management, routing, etc. Check [CoreContext] as underlying [Element] of this Widget.
  ///
  /// DO NOT call directly [register]/[registerStateNotifier] during build call - instead use [onInit] to register once.
  /// Within build method you can register state notifier with `context.use(.., stateNotifier = true)`;
  Widget build(CoreContext context);
}

/// Base class for concrete [ControlWidget]s with [ControlState].
/// ControlModels are initialized with [initControls] and stored in [ControlState.controls] and also in [CoreContext.args].
abstract class _ControlWidgetBase extends CoreWidget {
  /// Checks [args] and returns all [ControlModel]s during [initControls] and these Models will be initialized by this Widget.
  /// By default set to 'false' to prevent unintended rebuilds.
  bool get autoMountControls => false;

  const _ControlWidgetBase({
    super.key,
    super.initArgs,
  });

  @override
  ControlState createState() => ControlState();

  /// This is a place where to fill all required [ControlModel]s for this Widget.
  /// Called during Widget/State initialization phase.
  @protected
  List<ControlModel> initControls(CoreContext context) {
    return autoMountControls ? context.args.getAll<ControlModel>() : [];
  }

  /// Callback to notify state initialization completed.
  @protected
  void onInitState(ControlState state) {}

  /// Callback to notify state changes.
  @protected
  void onChangeState(ControlState state, dynamic value) {}

  /// Abstract rebuild implementation - override with proper [build] in concrete class.
  @protected
  Widget rebuild(CoreContext context);

  @override
  void onDispose() {
    super.onDispose();

    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// [State] of [_ControlWidgetBase].
/// Handles lifecycle of given [controls].
class ControlState<U extends _ControlWidgetBase> extends CoreState<U> {
  /// List of used Models.
  /// Both [CoreContext.args] and this List holds references to given Models.
  late List<ControlModel> controls;

  @override
  void onInit() {
    super.onInit();

    controls = widget.initControls(element);
    // Just ensure we have all controls in args.
    element.args.set(controls);

    controls.forEach((control) {
      control.init(element.args.data);
      control.mount(this);

      if (control is ReferenceCounter) {
        (control as ReferenceCounter).addReference(this);
      }

      if (control is ObservableBase) {
        element.registerStateNotifier(control);
      }
    });

    widget.onInitState(this);
  }

  @override
  void notifyState([dynamic state]) {
    if (mounted) {
      if (isDirty) {
        widget.onChangeState(this, state);
      } else {
        setState(() {
          widget.onChangeState(this, state);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.rebuild(element);

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();

    // Disposes and removes all [controls].
    // Models can prevent disposing [DisposeHandler.preventDispose].
    if (controls.isNotEmpty) {
      controls.forEach((control) {
        control.requestDispose(this);
      });
      controls.clear();
    }
  }
}
