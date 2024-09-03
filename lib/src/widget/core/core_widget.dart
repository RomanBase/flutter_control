part of flutter_control;

/// Base abstract Widget that controls [State], stores [args] and keeps Widget/State in harmony though lifecycle of Widget.
/// [CoreWidget] extends [StatefulWidget] and completely solves [State] specific flow. This solution helps to use it like [StatelessWidget], but with benefits of [StatefulWidget].
///
/// This Widget comes with [TickerControl] and [SingleTickerControl] mixin to create [Ticker] and provide access to [vsync]. Then use [ControlModel] with [TickerComponent] to get access to [TickerProvider].
///
/// [ControlWidget] - Can subscribe to multiple [ControlModel]s and is typically used for Pages and complex Widgets.
abstract class CoreWidget extends StatefulWidget {
  final Map initArgs;

  /// Base Control Widget that handles [State] flow.
  /// [args] - Arguments passed to this Widget and also to [ControlModel]s.
  ///
  /// Check [ControlWidget] and [ControllableWidget].
  const CoreWidget({
    super.key,
    this.initArgs = const {},
  });

  @override
  CoreContext createElement() => CoreContext(this, initArgs);

  @override
  CoreState createState();

  @protected
  @mustCallSuper
  void onInit(Map args, CoreContext context) {}

  /// Called whenever Widget needs update.
  /// Check [State.didUpdateWidget] for more info.
  @protected
  void onUpdate(CoreWidget oldWidget) {}

  /// Called whenever dependency of Widget is changed.
  /// Check [State.didChangeDependencies] for more info.
  @protected
  void onDependencyChanged(CoreContext context) {}

  @protected
  @mustCallSuper
  void onDispose() {}
}
