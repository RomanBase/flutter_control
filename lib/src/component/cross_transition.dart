part of flutter_control;

const _kCrossDuration = const Duration(milliseconds: 300);

/// Defines a transition between two widgets, typically used with [AnimatedSwitcher] or [CaseWidget].
/// It consists of two separate transitions: one for the widget coming in, and one for the widget going out.
class CrossTransition {
  static get _progress => Tween<double>(begin: 0.0, end: 1.0);

  /// The duration of the transition.
  final Duration duration;

  /// The duration of the reverse transition. If not provided, [duration] is used.
  final Duration? reverseDuration;

  /// The transition builder for the widget that is entering the view.
  final AnimatedSwitcherTransitionBuilder transitionIn;

  /// The transition builder for the widget that is leaving the view.
  final AnimatedSwitcherTransitionBuilder transitionOut;

  /// Creates a [CrossTransition].
  ///
  /// [duration] - The length of the animation.
  /// [transitionIn] - Builds the transition for the incoming widget.
  /// [transitionOut] - Builds the transition for the outgoing widget.
  const CrossTransition({
    this.duration = _kCrossDuration,
    this.reverseDuration,
    required this.transitionIn,
    required this.transitionOut,
  });

  /// Creates a [CrossTransition] where the incoming and outgoing widgets
  /// use the same transition builder.
  CrossTransition.single({
    this.duration = _kCrossDuration,
    this.reverseDuration,
    required AnimatedSwitcherTransitionBuilder transition,
  })  : transitionIn = transition,
        transitionOut = transition;

  /// Creates a [RouteTransitionFactory] for use with [ControlRouteTransition].
  ///
  /// This allows using a [CrossTransition] for page transitions, separating
  /// the animation of the incoming (foreground) and outgoing (background) pages.
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

  /// Builds the [AnimatedSwitcherTransitionBuilder] for this transition.
  ///
  /// If [reverse] is true, the in/out animations are swapped.
  AnimatedSwitcherTransitionBuilder build({bool reverse = false}) =>
      (child, anim) => _builder(child, anim, null, reverse);

  /// Builds a [RouteTransitionFactory] for this transition.
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

  /// A fade transition where the outgoing widget fades out partially before the new one fades in.
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

  /// A fade transition where the outgoing widget fades out completely before the new one fades in.
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

  /// A standard cross-fade transition.
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

  /// A slide transition. The incoming widget slides in from [begin] and the
  /// outgoing widget slides out towards [end].
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

  /// A scale and fade transition.
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
