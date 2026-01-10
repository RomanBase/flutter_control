part of flutter_control;

/// Extension hook on [CoreContext] to provide easy access to [AnimationController]s.
extension AnimationControllerHook on CoreContext {
  /// Provides an [_AnimationControllerProvider] for creating and managing [AnimationController] instances.
  ///
  /// The provider is hooked to the [CoreContext] lifecycle and will be disposed automatically.
  _AnimationControllerProvider get animation =>
      use<_AnimationControllerProvider>(
        value: () => _AnimationControllerProvider(ticker, this),
        dispose: (object) => object.dispose(),
      );
}

/// A provider class that manages a collection of [AnimationController]s.
/// It allows creating a default controller or multiple controllers identified by a key.
class _AnimationControllerProvider extends AnimationController {
  /// A map to store the created [AnimationController]s.
  final _items = <dynamic, AnimationController>{};

  /// The [TickerProvider] for the controllers.
  final TickerProvider ticker;

  /// The context to which this provider is attached.
  final CoreContext context;

  /// Provides an [AnimationController] by key.
  operator [](dynamic key) => this(key: key);

  _AnimationControllerProvider(this.ticker, this.context)
      : super(vsync: ticker);

  /// Retrieves or creates an [AnimationController].
  ///
  /// If [key] is `null`, it returns the default controller provided by this class itself.
  /// If a controller for the given [key] does not exist, a new one is created.
  ///
  /// [key] A unique identifier for the controller.
  /// [value] The initial value of the animation.
  /// [duration] The duration of the animation.
  /// [reverseDuration] The duration of the animation when running in reverse.
  /// [stateNotifier] If `true`, the controller will be registered as a state notifier,
  /// causing the widget to rebuild when the animation value changes.
  AnimationController call({
    dynamic key,
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    bool stateNotifier = false,
  }) {
    if (key == null) {
      if (!_items.containsKey(_AnimationControllerProvider)) {
        _items[_AnimationControllerProvider] = this;

        if (value != null) {
          this.value = value;
        }

        this.duration = duration;
        this.reverseDuration = reverseDuration;

        if (stateNotifier) {
          context.registerStateNotifier(this);
        }
      }

      return this;
    }

    if (!_items.containsKey(key)) {
      _items[key] = AnimationController(
        vsync: ticker,
        value: value,
        duration: duration,
        reverseDuration: reverseDuration,
        lowerBound: lowerBound,
        upperBound: upperBound,
        animationBehavior: animationBehavior,
      );

      if (stateNotifier) {
        context.registerStateNotifier(_items[key]!);
      }
    }

    return _items[key]!;
  }

  @override
  void dispose() {
    super.dispose();

    _items.remove(_AnimationControllerProvider);
    _items.forEach((key, value) => value.dispose());
  }
}
