import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';

import 'cards_controller.dart';
import 'cards_page.dart';
import 'menu_page.dart';
import 'settings_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      defaultLocale: 'en',
      locales: {
        'en': AssetPath().localization('en'),
        'cs': 'assets/localization/cs.json',
      },
      entries: {
        'cards': CardsController(),
      },
      initializers: {
        DetailController: (args) => DetailController(),
      },
      injector: Injector.of({
        ControlTheme: (item, args) => item.asset = AssetPath(rootDir: 'assets'),
      }),
      theme: (context) => MyTheme(context),
      loader: (context) => InitLoader.of(
        delay: Duration(seconds: 1),
        builder: (context) => Container(
          color: Colors.orange,
        ),
      ),
      routes: [
        ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
        ControlRoute.build<DetailPage>(builder: (_) => DetailPage()),
      ],
      root: (context, args) => MenuPage(),
      app: (context, key, home) => BroadcastBuilder<ThemeData>(
        key: 'theme',
        defaultValue: ThemeData(
          primaryColor: Colors.orange,
        ),
        builder: (context, theme) {
          return MaterialApp(
            key: key,
            title: 'Flutter Example',
            theme: theme,
            home: home,
          );
        },
      ),
    );
  }
}

class MyTheme extends ControlTheme {
  @override
  final padding = 24.0;

  @override
  final paddingHalf = 12.0;

  final superColor = Colors.red;

  MyTheme(BuildContext context) : super(context);
}
