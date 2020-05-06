import 'package:flutter_control/core.dart';

class NavTransitions {
  static RouteTransitionsBuilder get scaleTransition => (context, anim, anim2, child) {
        final offsetTween = Tween(begin: Offset(1.0, 1.0), end: Offset(0.0, 0.0));
        final scaleTween = Tween(begin: 0.0, end: 1.0);

        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeInCirc,
        );

        return ScaleTransition(
          scale: scaleTween.animate(curvedAnim),
          child: SlideTransition(
            position: offsetTween.animate(curvedAnim),
            child: child,
          ),
        );
      };

  static RouteWidgetBuilder get slideRoute => (builder, settings) => _SlideRoute(
        builder: builder,
        settings: settings,
      );
}

class _SlideRoute extends PageRoute {
  final WidgetBuilder builder;

  _SlideRoute({@required this.builder, RouteSettings settings}) : super(settings: settings);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final offsetTween = Tween(begin: Offset(1.0, -1.0), end: Offset(0.0, 0.0));

    final curvedAnim = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInCirc,
    );

    return SlideTransition(
      position: offsetTween.animate(curvedAnim),
      child: child,
    );
  }

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 500);
}
