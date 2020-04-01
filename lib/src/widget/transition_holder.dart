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
  final outKey = GlobalKey();
  final inKey = GlobalKey();

  bool autoRun = false;

  AnimationController animation;

  bool get isInitialized => animation != null;

  double get animTime => animation?.value ?? 0.0;

  TransitionControl();

  @override
  void onTickerInitialized(TickerProvider ticker) {
    animation = AnimationController(vsync: ticker);
    animation.addListener(() {
      notifyState();
    });
  }

  @override
  void onStateInitialized() {
    super.onStateInitialized();

    if (autoRun) {
      crossIn(from: 0.0);
    }
  }

  void setDurations({Duration forward, Duration reverse}) {
    assert(animation != null);

    animation.duration = forward ?? Duration(milliseconds: 300);
    animation.reverseDuration = reverse ?? Duration(milliseconds: 300);
  }

  void crossIn({double from}) {
    animation.forward(from: from);
  }

  void crossOut({double from}) {
    animation.reverse(from: from);
  }

  @override
  void dispose() {
    super.dispose();

    animation.dispose();
    animation = null;
  }
}

class TransitionInitHolder extends StateboundWidget<TransitionControl> with SingleTickerControl {
  final WidgetInitializer firstWidget;
  final WidgetInitializer secondWidget;
  final bool forceInit;
  final dynamic args;
  final CrossTransition transitionIn;
  final CrossTransition transitionOut;
  final VoidCallback onFinished;

  Animation get animation => control.animation;

  CrossTransitionBuilder get transitionInBuilder => transitionIn?.builder ?? CrossTransitions.fadeCross;

  CrossTransitionBuilder get transitionOutBuilder => transitionOut?.builder ?? CrossTransitions.fadeCross;

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

    control.setDurations(
      forward: transitionIn?.duration,
      reverse: transitionOut?.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final outWidget = KeyedSubtree(
      key: control.outKey,
      child: firstWidget.getWidget(
        context,
        forceInit: forceInit,
        args: args,
      ),
    );

    final inWidget = KeyedSubtree(
      key: control.inKey,
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

  factory TransitionHolder.forward({
    Key key,
    @required Widget firstWidget,
    @required Widget secondWidget,
    CrossTransition transitionIn,
    CrossTransition transitionOut,
    VoidCallback onFinished,
  }) =>
      TransitionHolder(
        key: key,
        control: TransitionControl()..autoRun = true,
        firstWidget: firstWidget,
        secondWidget: secondWidget,
        transitionIn: transitionIn,
        transitionOut: transitionOut,
        onFinished: onFinished,
      );

  @override
  void onInit(Map args) {
    control.setDurations(
      forward: transitionIn?.duration,
      reverse: transitionOut?.duration,
    );

    super.onInit(args);
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