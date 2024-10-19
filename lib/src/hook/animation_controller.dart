part of flutter_control;

extension AnimationControllerHook on CoreContext {
  _AnimationControllerProvider get animation =>
      use<_AnimationControllerProvider>(
        value: () => _AnimationControllerProvider(ticker, this),
        dispose: (object) => object.dispose(),
      )!;
}

class _AnimationControllerProvider extends AnimationController {
  final _items = <dynamic, AnimationController>{};
  final TickerProvider ticker;
  final CoreContext context;

  operator [](dynamic key) => this(key: key);

  _AnimationControllerProvider(this.ticker, this.context)
      : super(vsync: ticker);

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
