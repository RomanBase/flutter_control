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
  }

  void crossIn({double from}) {
    assert(isInitialized);

    animation?.forward(from: from);
  }

  void crossOut({double from}) {
    assert(isInitialized);

    animation?.reverse(from: from);
  }

  void _autoCrossRun() {
    assert(isInitialized);

    if (_autoCross != null) {
      _autoCross();
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

//TODO: as StatelessWidget with static constructor in TransitionHolder ????? !!!!!
class TransitionInitHolder extends StateboundWidget<TransitionControl> with SingleTickerControl {
  final bool forceInit;
  final dynamic args;
  final WidgetInitializer firstWidget;
  final WidgetInitializer secondWidget;
  final CrossTransition transitionIn;
  final CrossTransition transitionOut;
  final VoidCallback onFinished;

  Animation get animation => control.animation;

  CrossTransitionBuilder get transitionInBuilder => transitionIn?.builder ?? CrossTransitions.fadeCross;

  CrossTransitionBuilder get transitionOutBuilder => transitionOut?.builder ?? CrossTransitions.fadeCross;

  Key get _inKey => getArg(key: 'in_key');

  Key get _outKey => getArg(key: 'out_key');

  TransitionInitHolder({
    Key key,
    @required TransitionControl control,
    @required this.firstWidget,
    @required this.secondWidget,
    this.forceInit: false,
    this.args,
    this.transitionIn,
    this.transitionOut,
    this.onFinished,
  }) : super(key: key, control: control);

  @override
  void onInit(Map args) {
    super.onInit(args);

    _updateKeys();
    _updateDuration();
  }

  @override
  bool notifyUpdate(CoreWidget oldWidget) {
    final old = oldWidget as TransitionInitHolder;

    if (old.firstWidget != firstWidget || old.secondWidget != secondWidget) {
      _updateKeys();
      return true;
    }

    return super.notifyUpdate(oldWidget);
  }

  @override
  void onUpdate(CoreWidget oldWidget, CoreState<CoreWidget> state) {
    super.onUpdate(oldWidget, state);

    _updateDuration();

    if (control.autoRun) {
      control._autoCrossRun();
    }
  }

  void _updateKeys() {
    setArg(key: 'in_key', value: firstWidget.key ?? GlobalKey());
    setArg(key: 'out_key', value: secondWidget.key ?? GlobalKey());
  }

  void _updateDuration() {
    control.setDurations(
      forward: transitionIn?.duration,
      reverse: transitionOut?.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final outWidget = KeyedSubtree(
      key: _outKey,
      child: firstWidget.getWidget(
        context,
        forceInit: forceInit,
        args: args,
      ),
    );

    final inWidget = KeyedSubtree(
      key: _inKey,
      child: secondWidget.getWidget(
        context,
        forceInit: forceInit,
        args: args,
      ),
    );

    if (animation.value == 0.0) {
      if (onFinished != null) onFinished();

      return outWidget;
    }

    if (animation.value == 1.0) {
      if (onFinished != null) onFinished();

      return inWidget;
    }

    if (animation.status == AnimationStatus.forward) {
      return transitionInBuilder(
        context,
        animation,
        outWidget,
        inWidget,
      );
    } else {
      return transitionOutBuilder(
        context,
        animation,
        outWidget,
        inWidget,
      );
    }
  }
}

class TransitionHolder extends StateboundWidget<TransitionControl> with SingleTickerControl {
  final Widget firstWidget;
  final Widget secondWidget;
  final CrossTransition transitionIn;
  final CrossTransition transitionOut;
  final VoidCallback onFinished;

  Animation get animation => control.animation;

  CrossTransitionBuilder get transitionInBuilder => transitionIn?.builder ?? CrossTransitions.fadeCross;

  CrossTransitionBuilder get transitionOutBuilder => transitionOut?.builder ?? CrossTransitions.fadeCross;

  TransitionHolder({
    Key key,
    @required TransitionControl control,
    @required this.firstWidget,
    @required this.secondWidget,
    this.transitionIn,
    this.transitionOut,
    this.onFinished,
  }) : super(key: key, control: control);

  @override
  void onInit(Map args) {
    super.onInit(args);

    _updateDuration();
  }

  @override
  bool notifyUpdate(CoreWidget oldWidget) {
    final old = oldWidget as TransitionHolder;

    if (old.firstWidget != firstWidget || old.secondWidget != secondWidget) {
      return true;
    }

    return super.notifyUpdate(oldWidget);
  }

  @override
  void onUpdate(CoreWidget oldWidget, CoreState<CoreWidget> state) {
    super.onUpdate(oldWidget, state);

    _updateDuration();

    if (control.autoRun) {
      control._autoCrossRun();
    }
  }

  void _updateDuration() {
    control.setDurations(
      forward: transitionIn?.duration,
      reverse: transitionOut?.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (animation.value == 0.0) {
      if (onFinished != null && animation.status == AnimationStatus.reverse) onFinished();

      return firstWidget;
    }

    if (animation.value == 1.0) {
      if (onFinished != null && animation.status == AnimationStatus.forward) onFinished();

      return secondWidget;
    }

    if (animation.status == AnimationStatus.forward) {
      return transitionInBuilder(
        context,
        animation,
        firstWidget,
        secondWidget,
      );
    } else {
      return transitionOutBuilder(
        context,
        animation,
        firstWidget,
        secondWidget,
      );
    }
  }
}

class CrossTransitions {
  static get _progress => Tween<double>(begin: 0.0, end: 1.0);

  static get _progressReverse => Tween<double>(begin: 1.0, end: 0.0);

  static CrossTransitionBuilder get fade => (context, anim, firstWidget, secondWidget) {
        final outAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOut.to(0.65),
        );

        final inAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeIn.from(0.35),
        );

        return Container(
          color: Theme.of(context).backgroundColor,
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

  static CrossTransitionBuilder get fadeOutFadeIn => (context, anim, firstWidget, secondWidget) {
        final outAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeIn.to(0.35),
        );

        final inAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.ease.from(0.35),
        );

        return Container(
          color: Theme.of(context).backgroundColor,
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

  static CrossTransitionBuilder get fadeCross => (context, anim, firstWidget, secondWidget) {
        final outAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOut,
        );

        final inAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeIn,
        );

        return Container(
          color: Theme.of(context).backgroundColor,
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
