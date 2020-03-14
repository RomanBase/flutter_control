import 'dart:math' as math;

import 'package:flutter_control/core.dart';

import '../transition/nav_transitions.dart';
import 'number_page.dart';
import 'template_page.dart';

class MainPage extends ControlWidget with RouteControl {
  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      title: 'main page',
      color: Colors.blue,
      child: Column(
        children: <Widget>[
          RaisedButton(
            onPressed: () => Navigator.of(context).push(initRouteOf<NumberPage>(args: math.Random().nextInt(42))),
            child: Text('open page - nav'),
          ),
          RaisedButton(
            onPressed: () => routeOf<NumberPage>().openRoute(args: math.Random().nextInt(42)),
            child: Text('open page - control'),
          ),
          RaisedButton(
            onPressed: () => routeOf('/NumberPage/scale').openRoute(args: math.Random().nextInt(42)),
            child: Text('open page - scale transition'),
          ),
          RaisedButton(
            onPressed: () => routeOf<NumberPage>().viaRoute(NavTransitions.slideRoute).openRoute(args: math.Random().nextInt(42)),
            child: Text('open page - slide route'),
          ),
        ],
      ),
    );
  }
}
