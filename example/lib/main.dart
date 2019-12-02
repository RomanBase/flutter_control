import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';

import 'cards_controller.dart';
import 'menu_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlBase(
      defaultLocale: 'en',
      locales: {
        'en': 'assets/localization/en.json',
        'cs': 'assets/localization/cs.json',
      },
      entries: {
        'cards': CardsController(),
      },
      initializers: {
        DetailController: () => DetailController(),
      },
      root: (context) => MenuPage(),
      app: (BuildContext context, Key key, Widget home) {
        return MaterialApp(
          key: key,
          home: home,
          title: 'Flutter Control Example',
        );
      },
    );
  }
}
