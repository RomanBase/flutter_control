part of flutter_control;

const _kCrossDuration = const Duration(milliseconds: 300);

/// Holds anim duration and transition builder.
class CrossTransition {
  static get _progress => Tween<double>(begin: 0.0, end: 1.0);

  /// Duration/length of animated transition.
  final Duration duration;

  /// Duration/length of animated transition.
  final Duration? reverseDuration;

  final AnimatedSwitcherTransitionBuilder transitionIn;
  final AnimatedSwitcherTransitionBuilder transitionOut;

  /// [duration] - [Animation] length.
  /// [transition] - Builds Transition Widget based on input [Animation] and in/out Widgets.
  const CrossTransition({
    this.duration = _kCrossDuration,
    this.reverseDuration,
    required this.transitionIn,
    required this.transitionOut,
  });

  CrossTransition.single({
    this.duration = _kCrossDuration,
    this.reverseDuration,
    required AnimatedSwitcherTransitionBuilder transition,
  })  : transitionIn = transition,
        transitionOut = transition;

  static RouteTransitionFactory route(
          {required CrossTransition background,
          required CrossTransition foreground,
          bool reverse = false}) =>
      (context, setup, child) {
        if (setup.backgroundActive && setup.foregroundActive) {
          return child;
        }

        if (setup.backgroundActive) {
          if (setup.backgroundIncoming) {
            return background.transitionIn
                .call(child, ReverseAnimation(setup.outgoingAnimation));
          }

          if (setup.backgroundOutgoing) {
            return background.transitionOut
                .call(child, ReverseAnimation(setup.outgoingAnimation));
          }
        }

        if (setup.foregroundActive) {
          if (setup.foregroundIncoming) {
            return foreground.transitionIn.call(child, setup.incomingAnimation);
          }

          if (setup.foregroundOutgoing) {
            return foreground.transitionOut
                .call(child, setup.incomingAnimation);
          }
        }

        return child;
      };

  AnimatedSwitcherTransitionBuilder build({bool reverse = false}) =>
      (child, anim) => _builder(child, anim, null, reverse);

  RouteTransitionFactory buildRoute({bool reverse = false}) =>
      route(background: this, foreground: this, reverse: reverse);

  Widget _builder(Widget child, Animation<double> animation,
      Animation<double>? secondaryAnimation,
      [bool reverse = false]) {
    final animateForward = reverse
        ? (animation.status == AnimationStatus.dismissed ||
            animation.status == AnimationStatus.reverse)
        : (animation.status == AnimationStatus.completed ||
            animation.status == AnimationStatus.forward);

    if (animateForward) {
      return transitionIn.call(child, animation);
    }

    return transitionOut.call(child, animation);
  }

  factory CrossTransition.fade({
    Duration? duration,
    Duration? reverseDuration,
    Curve curveIn = const IntervalCurve(Curves.easeIn, begin: 0.35),
    Curve curveOut = const IntervalCurve(Curves.easeOut, begin: 0.35),
  }) =>
      CrossTransition(
        duration: duration ?? _kCrossDuration,
        reverseDuration: reverseDuration,
        transitionIn: (child, anim) => FadeTransition(
          opacity: _progress.animate(CurvedAnimation(
            parent: anim,
            curve: curveIn,
          )),
          child: child,
        ),
        transitionOut: (child, anim) => FadeTransition(
          opacity: _progress.animate(CurvedAnimation(
            parent: anim,
            curve: curveOut,
          )),
          child: child,
        ),
      );

  factory CrossTransition.fadeOutFadeIn({
    Duration? duration,
    Duration? reverseDuration,
  }) =>
      CrossTransition.fade(
        duration: duration,
        reverseDuration: reverseDuration,
        curveIn: Curves.ease.from(0.35), // 0.35 -> 1.0
        curveOut: Curves.easeIn.to(0.35).reversed, // 1.0 -> 0.65
      );

  factory CrossTransition.fadeCross({
    Duration? duration,
    Duration? reverseDuration,
  }) =>
      CrossTransition.fade(
        duration: duration,
        reverseDuration: reverseDuration,
        curveIn: Curves.easeIn,
        curveOut: Curves.easeOut,
      );

  factory CrossTransition.slide({
    Duration? duration,
    Duration? reverseDuration,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = const Offset(-1.0, 0.0),
    Curve curveIn = Curves.easeIn,
    Curve curveOut = Curves.easeOut,
  }) =>
      CrossTransition(
        duration: duration ?? _kCrossDuration,
        reverseDuration: reverseDuration,
        transitionIn: (child, anim) => SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset(0.0, 0.0))
              .animate(CurvedAnimation(
            parent: anim,
            curve: curveIn,
          )),
          child: child,
        ),
        transitionOut: (child, anim) => SlideTransition(
          position: Tween<Offset>(begin: end, end: Offset(0.0, 0.0))
              .animate(CurvedAnimation(
            parent: anim,
            curve: curveOut,
          )),
          child: child,
        ),
      );

  factory CrossTransition.scale({
    Duration? duration,
    Duration? reverseDuration,
    double begin = 1.25,
    double end = 0.75,
    Curve curveIn = Curves.easeIn,
    Curve curveOut = Curves.easeOut,
    Curve fadeIn = Curves.easeInQuad,
    Curve fadeOut = Curves.easeOut,
  }) =>
      CrossTransition(
        duration: duration ?? _kCrossDuration,
        reverseDuration: reverseDuration,
        transitionIn: (child, anim) => ScaleTransition(
          scale: Tween<double>(begin: begin, end: 1.0).animate(CurvedAnimation(
            parent: anim,
            curve: curveIn,
          )),
          child: FadeTransition(
            opacity: _progress.animate(CurvedAnimation(
              parent: anim,
              curve: fadeIn,
            )),
            child: child,
          ),
        ),
        transitionOut: (child, anim) => ScaleTransition(
          scale: Tween<double>(begin: end, end: 1.0).animate(CurvedAnimation(
            parent: anim,
            curve: curveIn,
          )),
          child: FadeTransition(
            opacity: _progress.animate(CurvedAnimation(
              parent: anim,
              curve: fadeOut,
            )),
            child: child,
          ),
        ),
      );
}
