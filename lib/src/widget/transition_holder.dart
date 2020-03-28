import 'package:flutter_control/core.dart';

typedef CrossTransitionBuilder = Widget Function(BuildContext context, Animation anim, Widget outWidget, Widget inWidget);

class CrossTransition {
  final Duration duration;
  final CrossTransitionBuilder builder;

  const CrossTransition({
    this.duration: const Duration(milliseconds: 300),
    @required this.builder,
  });
}

class TransitionControl extends ControlModel with StateControl, TickerComponent {
  final Duration duration;

  AnimationController animation;

  TransitionControl({this.duration: const Duration(milliseconds: 300)});

  @override
  void onTickerInitialized(TickerProvider ticker) {
    animation = AnimationController(vsync: ticker, duration: duration);
  }

  void forward() => animation.forward();

  void reverse() => animation.reverse();

  @override
  void dispose() {
    super.dispose();

    animation.dispose();
  }
}

class TransitionInitHolder extends StateboundWidget<TransitionControl> with SingleTickerControl {
  final WidgetInitializer firstWidget;
  final WidgetInitializer secondWidget;
  final bool forceInit;
  final dynamic args;
  final CrossTransitionBuilder transition;
  final bool clear;
  final VoidCallback onFinished;

  Animation get animation => control.animation;

  TransitionInitHolder({
    Key key,
    @required TransitionControl control,
    @required this.firstWidget,
    @required this.secondWidget,
    this.forceInit: false,
    this.args,
    this.transition,
    this.clear: false,
    this.onFinished,
  }) : super(key: key, control: control);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        Widget outWidget = firstWidget.getWidget(context, forceInit: forceInit, args: args);
        if (animation.value == 0.0) {
          if (animation.status == AnimationStatus.reverse && clear) {
            secondWidget.clear();
          }

          if (onFinished != null) onFinished();

          return outWidget;
        }

        Widget inWidget = secondWidget.getWidget(context, forceInit: forceInit, args: args);
        if (animation.value == 1.0) {
          if (animation.status == AnimationStatus.forward && clear) {
            firstWidget.clear();
          }

          if (onFinished != null) onFinished();

          return inWidget;
        }

        return (transition ?? CrossTransitions.fade)(
          context,
          animation,
          outWidget,
          inWidget,
        );
      },
    );
  }
}

class CrossTransitions {
  static get _progress => Tween<double>(begin: 0.0, end: 1.0);

  static get _progressReverse => Tween<double>(begin: 1.0, end: 0.0);

  static CrossTransitionBuilder get fade => (context, anim, outWidget, inWidget) {
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
                child: outWidget,
              ),
              FadeTransition(
                opacity: _progress.animate(inAnim),
                child: inWidget,
              )
            ],
          ),
        );
      };
}
