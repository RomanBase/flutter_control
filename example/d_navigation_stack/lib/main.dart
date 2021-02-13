import 'package:d_navigation_stack/page/dialog_page.dart';
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
      entries: {
        NavigatorStackControl: NavigatorStackControl(),
      },
      routes: [
        ControlRoute.build<NumberPage>(builder: (_) => NumberPage())
            .viaCupertinoRoute(),
        ControlRoute.build<NumberPage>(builder: (_) => NumberPage())
            .path('/scale')
            .viaTransition(
                NavTransitions.scaleTransition, Duration(milliseconds: 750)),
        ControlRoute.build<CustomDialog>(builder: (_) => CustomDialog()),
      ],
      states: [
        AppState.main.build((context) => MenuPage()),
      ],
      app: (setup, home) => MaterialApp(
        key: setup.key,
        home: home,
        title: 'Navigation - Flutter Control',
      ),
    );
  }
}
