import 'package:flutter_control/core.dart';

typedef CrossTransitionBuilder = Widget Function(BuildContext context, Animation anim, Widget firstWidget, Widget secondWidget);

/// Holds anim duration and transition builder.
class CrossTransition {
  /// Duration/length of animated transition.
  final Duration duration;

  /// Builds Transition Widget based on input [Animation] and in/out Widgets.
  /// Check [CrossTransitions] for default builders.
  final CrossTransitionBuilder builder;

  /// [duration] - [Animation] length.
  /// [builder] - Builds Transition Widget based on input [Animation] and in/out Widgets.
  const CrossTransition({
    this.duration: const Duration(milliseconds: 300),
    @required this.builder,
  });
}

/// Handles transition progress and animation.
class TransitionControl extends BaseModel with StateControl, TickerComponent {
  /// Enables auto run - animation is played automatically when Widget is build.
  /// Can't be null.
  bool autoRun;

  //TODO: make it private ? Prevent using this controller outside of class.
  /// Animation Controller created when [TickerComponent] provides [vsync].
  AnimationController animation;

  /// Checks if [animation] is ready.
  bool get isInitialized => animation != null;

  /// Callback of [autoRun] action.
  VoidCallback _autoCross;

  /// Sets next animation value.
  double progress;

  /// Returns current [animation] progress.
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

  /// Changes duration of [forward] and [reverse] animation.
  /// 300ms is used if duration is not set.
  /// Animation value is set to current [progress].
  void setDurations({Duration forward, Duration reverse}) {
    assert(isInitialized);

    animation.duration = forward ?? Duration(milliseconds: 300);
    animation.reverseDuration = reverse ?? Duration(milliseconds: 300);
    animation.value = progress ?? 0.0;
  }

  /// Plays cross in transition: 0.0 -> 1.0. From first widget to second.
  /// [AnimationController.forward].
  TickerFuture crossIn({double from}) {
    assert(isInitialized);

    return animation.forward(from: from);
  }

  /// Plays cross out transition: 1.0 -> 0.0. From second widget to first.
  /// [AnimationController.forward].
  TickerFuture crossOut({double from}) {
    assert(isInitialized);

    return animation.reverse(from: from);
  }

  /// Plays [autoRun] cross animation.
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

  /// Prepares control to play [crossIn] after [State] initialization.
  void autoCrossIn({double from}) {
    autoRun = true;
    _autoCross = () => crossIn(from: from);
  }

  /// Prepares control to play [crossOut] after [State] initialization.
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

/// Handles transition between two Widgets.
/// This transition is controlled by [TransitionControl] and can be played both ways.
/// Only one [Widget] is used at given time, second [Widget] is disposed when animation ends.
class TransitionHolder extends StateboundWidget<TransitionControl> with SingleTickerControl {
  /// Arg key for first widget. Actual [Key] is stored in [ControlArgHolder].
  static const _firstKey = 'first_key';

  /// Arg key for second widget. Actual [Key] is stored in [ControlArgHolder].
  static const _secondKey = 'second_key';

  /// Arguments to pass to [Widget] during initialization.
  final dynamic args;

  /// Builder of first Widget. By default this Widget is visible initially.
  /// Custom [WidgetInitializer.key] can help to prevent unnecessary rebuilds, when swapping initializers or moving in [WidgetTree]. Otherwise [UniqueKey] is generated.
  final WidgetInitializer firstWidget;

  /// Builder of second Widget. By default this Widget is hidden initially.
  /// Custom [WidgetInitializer.key] can help to prevent unnecessary rebuilds, when swapping initializers or moving in [WidgetTree]. Otherwise [UniqueKey] is generated.
  final WidgetInitializer secondWidget;

  /// Transition from [firstWidget] to [secondWidget].
  /// [CrossTransitions.fadeCross] is used by default.
  final CrossTransition transitionIn;

  /// Transition from [secondWidget] to [firstWidget].
  /// [CrossTransitions.fadeCross] is used by default.
  final CrossTransition transitionOut;

  /// Callback when transition is finished.
  final VoidCallback onFinished;

  /// Returns current animation controller.
  Animation get animation => control.animation;

  /// Returns transition for [TransitionControl.crossIn].
  CrossTransitionBuilder get transitionInBuilder => transitionIn?.builder ?? CrossTransitions.fadeCross();

  /// Returns transition for [TransitionControl.crossOut].
  CrossTransitionBuilder get transitionOutBuilder => transitionOut?.builder ?? CrossTransitions.fadeCross();

  /// Keyed first Widget.
  Widget get _firstWidget => KeyedSubtree(
        key: getArg(key: _firstKey),
        child: firstWidget.getWidget(context, args: args),
      );

  /// Keyed second Widget.
  Widget get _secondWidget => KeyedSubtree(
        key: getArg(key: _secondKey),
        child: secondWidget.getWidget(context, args: args),
      );

  /// Handles transition between two Widgets and holds active [Widget], other Widget is disposed.
  /// [control] - Handles animation controller and Widget crossing. Dispose this [control] a
  /// [firstWidget] - Initial Widget. By default this Widget is visible initially.
  /// [secondWidget] - By default this Widget is hidden initially.
  /// [args] - Arguments passed to Widgets.
  /// [transitionIn] - Transition from first to second.
  /// [transitionOut] - Transition from second to first.
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
  void onUpdate(CoreWidget oldWidget) {
    final old = oldWidget as TransitionHolder;

    if (old.firstWidget != firstWidget || old.secondWidget != secondWidget) {
      _updateKeys();
      _updateDuration();

      if (control.autoRun) {
        control._autoCrossRun();
      }
    }
  }

  /// Resets keys.
  void _updateKeys() {
    setArg(key: _firstKey, value: firstWidget.key ?? GlobalKey());
    setArg(key: _secondKey, value: secondWidget.key ?? GlobalKey());
  }

  /// Updates duration of transitions.
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
