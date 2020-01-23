import 'package:flutter_control/core.dart';

import './page/number_page.dart';
import './transition/nav_transitions.dart';
import 'menu_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      entries: {
        TabControl: TabControl(),
      },
      routes: [
        ControlRoute.build<NumberPage>(builder: (_) => NumberPage()),
        ControlRoute.build<NumberPage>(builder: (_) => NumberPage()).path('/scale').viaTransition(NavTransitions.scaleTransition, Duration(milliseconds: 750)),
      ],
      root: (_, __) => MenuPage(),
      app: (context, key, home) => MaterialApp(
        key: key,
        home: home,
        title: 'Navigation - Flutter Control',
      ),
    );
  }
}
