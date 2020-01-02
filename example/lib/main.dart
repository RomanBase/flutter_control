import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';
import 'package:flutter_control_example/menu_page.dart';

import 'cards_controller.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget with LocalizationProvider, PrefsProvider {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlBase(
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
      root: (context) => MenuPage(),
      app: (context, home) => BroadcastBuilder<ThemeData>(
        key: 'theme',
        defaultValue: ThemeData(
          primaryColor: Colors.orange,
        ),
        builder: (context, theme) {
          return MaterialApp(
            title: localizeDynamic('app_name', defaultValue: 'Flutter Example') as String,
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
