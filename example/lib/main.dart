import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';

import 'cards_controller.dart';
import 'cards_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BaseApp(
      title: 'Flutter Control Example',
      locales: {
        'en': 'assets/localization/en.json',
      },
      entries: {
        'cards': CardsController(),
      },
      initializers: {
        DetailController: () => DetailController(),
      },
      root: (context) => CardsPage(),
    );
  }
}
