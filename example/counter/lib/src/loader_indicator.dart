import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_control/control.dart';

class LoaderVisibility extends ControllableWidget<FieldControl<LoadingStatus>> {
  final WidgetBuilder builder;
  final Widget? placeholder;
  final CrossTransition? transition;

  const LoaderVisibility({
    super.key,
    required super.control,
    required this.builder,
    this.placeholder,
    this.transition,
  });

  @override
  Widget build(BuildContext context) {
    return CaseWidget(
      activeCase: control.value,
      builders: {
        LoadingStatus.done: builder,
      },
      placeholder: (_) => placeholder ?? Container(),
      transition: transition,
    );
  }
}

class LoaderStepIndicator extends BaseControlWidget {
  final int count;
  final Color? color;
  final Duration duration;
  final Curve curve;
  final Size size;
  final double bounce;
  final double spacing;

  const LoaderStepIndicator({
    Key? key,
    this.count = 24,
    this.color = Colors.black38,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOut,
    this.size = const Size(6.0, 32.0),
    this.bounce = 12.0,
    this.spacing = 0.0,
  }) : super(key: key);

  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    _initRandom(context);

    final step = context.animation(
      duration: duration,
      stateNotifier: true,
    );

    step.repeat(reverse: true);
    step.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        _initRandom(context);
      }
    });
  }

  void _initRandom(CoreContext context) {
    final random = math.Random(DateTime.now().millisecondsSinceEpoch);
    for (int i = 0; i < count; i++) {
      final begin = random.nextDouble() * 0.25;
      context.set(
        key: i,
        value:
            curve.inRange(begin, (begin + random.nextDouble()).clamp(0.5, 1.0)),
      );
    }
  }

  @override
  Widget build(CoreContext context) {
    final progress = context.animation.value;
    Curve Function(int index) curve = (i) => context.get<Curve>(key: i)!;

    return SizedBox(
      height: size.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < count; i++)
            Container(
              margin: EdgeInsets.symmetric(horizontal: spacing * 0.5).add(
                  EdgeInsets.only(
                      bottom: (bounce * (math.sin(progress) + 1.0) * 0.25),
                      top: (bounce * (math.sin(progress) + 1.0) * 0.25))),
              width: size.width,
              height: curve(i).transform(progress) * size.height,
              decoration: BoxDecoration(
                //borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
