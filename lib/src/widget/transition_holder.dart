import 'package:flutter_control/core.dart';

typedef CrossTransitionBuilder = Widget Function(BuildContext context, Animation anim, Widget firstWidget, Widget secondWidget);

class CrossTransition {
  final Duration duration;
  final CrossTransitionBuilder builder;

  const CrossTransition({
    this.duration: const Duration(milliseconds: 300),
    @required this.builder,
  });
}

class TransitionControl extends ControlModel with StateControl, TickerComponent {
  bool autoRun;

  AnimationController animation;

  bool get isInitialized => animation != null;

  double get animTime => animation?.value ?? 0.0;

  VoidCallback _autoCross;

  double progress;

  double get transitionProgress => animation?.value ?? 0.0;

  TransitionControl({this.autoRun: false});

  @override
  void onTickerInitialized(TickerProvider ticker) {
    animation = AnimationController(vsync: ticker, duration: Duration(milliseconds: 300));
    animation.addListener(() {
      notifyState();
    });
  }

  @override
  void onStateInitialized() {
    super.onStateInitialized();

    if (autoRun) {
      _autoCrossRun();
    }
  }

  void setDurations({Duration forward, Duration reverse}) {
    assert(isInitialized);

    animation.duration = forward ?? Duration(milliseconds: 300);
    animation.reverseDuration = reverse ?? Duration(milliseconds: 300);
    animation.value = progress ?? 0.0;
  }

  void crossIn({double from}) {
    assert(isInitialized);

    animation.forward(from: from);
  }

  void crossOut({double from}) {
    assert(isInitialized);

    animation.reverse(from: from);
  }

  void _autoCrossRun() {
    assert(isInitialized);

    if (_autoCross != null) {
      _autoCross();
      return;
    }

    if (animation.value < 1.0) {
      crossIn();
    } else {
      crossOut();
    }
  }

  void autoCrossIn({double from}) {
    autoRun = true;
    _autoCross = () => crossIn(from: from);
  }

  void autoCrossOut({double from}) {
    autoRun = true;
    _autoCross = () => crossOut(from: from);
  }

  @override
  void dispose() {
    super.dispose();

    animation?.dispose();
    animation = null;
  }
}

class TransitionHolder extends StateboundWidget<TransitionControl> with SingleTickerControl {
  final dynamic args;
  final WidgetInitializer firstWidget;
  final WidgetInitializer secondWidget;
  final CrossTransition transitionIn;
  final CrossTransition transitionOut;
  final VoidCallback onFinished;

  Animation get animation => control.animation;

  CrossTransitionBuilder get transitionInBuilder => transitionIn?.builder ?? CrossTransitions.fadeCross();

  CrossTransitionBuilder get transitionOutBuilder => transitionOut?.builder ?? CrossTransitions.fadeCross();

  Widget get _firstWidget => KeyedSubtree(
        key: getArg(key: 'first_key'),
        child: firstWidget.getWidget(context, args: args),
      );

  Widget get _secondWidget => KeyedSubtree(
        key: getArg(key: 'second_key'),
        child: secondWidget.getWidget(context, args: args),
      );

  TransitionHolder({
    Key key,
    @required TransitionControl control,
    @required this.firstWidget,
    @required this.secondWidget,
    this.args,
    this.transitionIn,
    this.transitionOut,
    this.onFinished,
  }) : super(key: key, control: control);

  @override
  void onInit(Map args) {
    super.onInit(args);

    _updateKeys();

    if (!control.isInitialized) {
      _updateDuration();
    }
  }

  @override
  bool shouldUpdate(CoreWidget oldWidget) {
    final update = super.shouldUpdate(oldWidget);

    final old = oldWidget as TransitionHolder;

    if (old.firstWidget != firstWidget || old.secondWidget != secondWidget) {
      _updateKeys();
      _updateDuration();

      if (control.autoRun) {
        control._autoCrossRun();
      }
    }

    return update;
  }

  void _updateKeys() {
    setArg(key: 'first_key', value: firstWidget.key ?? GlobalKey());
    setArg(key: 'second_key', value: secondWidget.key ?? GlobalKey());
  }

  void _updateDuration() {
    control.setDurations(
      forward: transitionIn?.duration,
      reverse: transitionOut?.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (animation.status == AnimationStatus.dismissed) {
      if (onFinished != null) onFinished();

      secondWidget.clear();
      return _firstWidget;
    }

    if (animation.status == AnimationStatus.completed) {
      if (onFinished != null) onFinished();

      firstWidget.clear();
      return _secondWidget;
    }

    if (animation.status == AnimationStatus.forward) {
      return transitionInBuilder(
        context,
        animation,
        _firstWidget,
        _secondWidget,
      );
    } else {
      return transitionOutBuilder(
        context,
        animation,
        _firstWidget,
        _secondWidget,
      );
    }
  }
}

class CrossTransitions {
  static get _progress => Tween<double>(begin: 0.0, end: 1.0);

  static get _progressReverse => Tween<double>(begin: 1.0, end: 0.0);

  static CrossTransitionBuilder fade({Color backgroundColor}) => (context, anim, firstWidget, secondWidget) {
        final outAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOut.to(0.65),
        );

        final inAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeIn.from(0.35),
        );

        return Container(
          color: backgroundColor ?? Theme.of(context).backgroundColor,
          child: Stack(
            children: <Widget>[
              FadeTransition(
                opacity: _progressReverse.animate(outAnim),
                child: firstWidget,
              ),
              FadeTransition(
                opacity: _progress.animate(inAnim),
                child: secondWidget,
              )
            ],
          ),
        );
      };

  static CrossTransitionBuilder fadeOutFadeIn({Color backgroundColor}) => (context, anim, firstWidget, secondWidget) {
        final outAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeIn.to(0.35),
        );

        final inAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.ease.from(0.35),
        );

        return Container(
          color: backgroundColor ?? Theme.of(context).backgroundColor,
          child: Stack(
            children: <Widget>[
              FadeTransition(
                opacity: _progressReverse.animate(outAnim),
                child: firstWidget,
              ),
              FadeTransition(
                opacity: _progress.animate(inAnim),
                child: secondWidget,
              )
            ],
          ),
        );
      };

  static CrossTransitionBuilder fadeCross({Color backgroundColor}) => (context, anim, firstWidget, secondWidget) {
        final outAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOut,
        );

        final inAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeIn,
        );

        return Container(
          color: backgroundColor ?? Theme.of(context).backgroundColor,
          child: Stack(
            children: <Widget>[
              FadeTransition(
                opacity: _progressReverse.animate(outAnim),
                child: firstWidget,
              ),
              FadeTransition(
                opacity: _progress.animate(inAnim),
                child: secondWidget,
              )
            ],
          ),
        );
      };
}
