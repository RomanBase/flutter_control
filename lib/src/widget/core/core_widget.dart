part of flutter_control;

/// Base abstract [StatefulWidget], that creates [CoreContext].
///
/// Check [CoreState] as counterpart of this Widget.
/// Check [ControlWidget] and their variants as concrete implementation of this class.
abstract class CoreWidget extends StatefulWidget {
  /// Init args of this widget.
  /// This is passed to [CoreContext]. Retrieve concrete arg with [CoreContext._get], [CoreContext.use] when needed.
  final Map initArgs;

  /// Abstract implementation of base control widget, that initializes [CoreContext] and handles state management and lifecycle of given resources.
  /// [initArgs] are passed to [CoreContext].
  const CoreWidget({
    super.key,
    this.initArgs = const {},
  });

  @override
  CoreContext createElement() => CoreContext(this);

  @override
  CoreState createState();

  /// Initial widget initialization.
  /// Use your mixins here.
  @protected
  void init(CoreContext context) {}

  /// Called right after initState and before build.
  /// [context] is here fully usable without restrictions.
  ///
  /// Best place to register state notifiers, hooks and other resources.
  ///
  /// Check [InitProvider] and [LazyProvider] mixins to alter [args].
  /// Check [OnLayout] mixin to process resources after view is adjusted.
  @protected
  @mustCallSuper
  void onInit(Map args, CoreContext context) {}

  /// Called whenever Widget requests update.
  /// Check [State.didUpdateWidget] for more info.
  /// Just callback from State.
  @protected
  void onUpdate(CoreContext context, CoreWidget oldWidget) {}

  /// Called whenever dependency of Widget is changed.
  /// Check [State.didChangeDependencies] for more info.
  /// Just callback from State.
  @protected
  void onDependencyChanged(CoreContext context) {}

  @protected
  @mustCallSuper
  void onDispose() {}
}
