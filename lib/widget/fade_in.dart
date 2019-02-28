import 'package:flutter_control/core.dart';

class _FadeInController extends StateController {
  final Duration duration;

  _FadeInController(this.duration);

  AnimationController _anim;

  @override
  void onTickerInitialized(TickerProvider ticker) {
    _anim = AnimationController(vsync: ticker, duration: duration);
  }

  AnimationController fadeIn() {
    _anim?.forward(from: 0.0);
    return _anim;
  }

  AnimationController fadeOut() {
    _anim?.reverse();
    return _anim;
  }

  @override
  void dispose() {
    super.dispose();

    _anim?.dispose();
  }
}

class FadeIn extends BaseWidget<_FadeInController> {
  final Widget child;

  FadeIn({Key key, Duration duration, this.child}) : super(key: key, controller: _FadeInController(duration ?? Duration(milliseconds: 500)), ticker: true);

  @override
  Widget buildWidget(BuildContext context, _FadeInController controller) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: controller.fadeIn(), curve: Curves.easeIn)),
      child: child,
    );
  }
}
