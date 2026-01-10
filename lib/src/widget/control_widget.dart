part of flutter_control;

/// A lightweight [CoreWidget] for building UI without requiring a dedicated [ControlModel].
///
/// It still provides a [CoreContext] for accessing dependencies and state from
/// parent widgets, but it does not manage its own list of controls.
/// Multiple observers and state notifiers can still request a rebuild of this widget.
///
/// Use this for simple widgets that need to react to external state but don't
/// have complex internal logic.
///
/// - [onInit] is called once when the state is initialized.
/// - [build] is called to build the widget's UI.
abstract class BaseControlWidget extends CoreWidget {
  const BaseControlWidget({
    super.key,
    super.initArgs,
  });

  @override
  CoreState<CoreWidget> createState() => BaseControlState();

  /// Builds the widget's UI.
  ///
  /// Use [context] to work with framework features like dependency lookup,
  /// state management, and navigation.
  ///
  /// Do not register long-lived dependencies here. Use [onInit] for that purpose.
  Widget build(CoreContext context);
}

/// The state for a [BaseControlWidget].
class BaseControlState extends CoreState<BaseControlWidget> {
  @override
  Widget build(BuildContext context) => widget.build(element);
}

/// A [CoreWidget] that is tightly coupled with a single primary [ControlModel] of type [T].
///
/// This widget automatically initializes and provides the [control] of type [T]
/// to the [build] method. The control is resolved from the widget's arguments
/// or the global [ControlFactory].
///
/// Use this when a widget's logic is primarily managed by one `ControlModel`.
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

  /// Initializes the primary [ControlModel] of type [T].
  ///
  /// By default, it tries to resolve the control from the widget's arguments
  /// using [Control.resolve]. Subclasses can override this to provide a
  /// custom initialization strategy.
  @protected
  T? initControl(CoreContext context) => Control.resolve<T>(context.args);

  @override
  Widget rebuild(CoreContext context) => build(context, context<T>());

  /// Builds the widget's UI with access to the primary [control].
  ///
  /// Use [context] for framework features and [control] for business logic and state.
  Widget build(CoreContext context, T control);
}

/// A flexible [CoreWidget] that can manage multiple [ControlModel]s.
///
/// This is a general-purpose widget for building UI that depends on one or more
/// `ControlModel`s. Dependencies are initialized in [initControls] and can be
/// accessed within the [build] method via `context.get<T>()`.
abstract class ControlWidget extends _ControlWidgetBase {
  const ControlWidget({
    super.key,
    super.initArgs,
  });

  @override
  Widget rebuild(CoreContext context) => build(context);

  /// Builds the widget's UI.
  ///
  /// Use [context] to access dependencies, manage state, and navigate.
  Widget build(CoreContext context);
}

/// The base class for widgets that manage a list of [ControlModel]s.
///
/// It handles the initialization and disposal of controls provided via the
/// [initControls] method.
abstract class _ControlWidgetBase extends CoreWidget {
  /// If `true`, all [ControlModel]s found in the widget's arguments will be
  /// automatically initialized and mounted. Defaults to `false`.
  bool get autoMountControls => false;

  const _ControlWidgetBase({
    super.key,
    super.initArgs,
  });

  @override
  ControlState createState() => ControlState();

  /// Returns a list of [ControlModel]s to be initialized and managed by this widget.
  /// This method is called once during state initialization.
  @protected
  List<ControlModel> initControls(CoreContext context) {
    return autoMountControls ? context.args.getAll<ControlModel>() : [];
  }

  /// Called after the state and all its controls have been initialized.
  @protected
  void onInitState(ControlState state) {}

  /// Called when the state is notified of a change from one of its notifiers.
  @protected
  void onChangeState(ControlState state, dynamic value) {}

  /// Abstract method for building the widget's UI.
  /// Implemented by subclasses like [ControlWidget] and [SingleControlWidget].
  @protected
  Widget rebuild(CoreContext context);

  @override
  void onDispose() {
    super.onDispose();

    printDebug('dispose: ${this.runtimeType.toString()}');
  }
}

/// The [State] object for a [_ControlWidgetBase].
///
/// It manages the lifecycle of the [ControlModel]s provided by the widget.
class ControlState<U extends _ControlWidgetBase> extends CoreState<U> {
  /// The list of [ControlModel]s managed by this state.
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
