import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';
import 'package:flutter_control_example/cross_page.dart';

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
      localization: LocalizationConfig(
        defaultLocale: 'en',
        locales: {
          'en': AssetPath().localization('en'),
          'cs': 'assets/localization/cs.json',
        },
      ),
      entries: {
        'cards': CardsController(),
      },
      initializers: {
        DetailController: (args) => DetailController(),
        CrossControl: (args) => CrossControl(),
      },
      injector: Injector.of({
        ControlTheme: (item, args) => item.asset = AssetPath(rootDir: 'assets'),
      }),
      routes: [
        ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
        ControlRoute.build<DetailPage>(builder: (_) => DetailPage()),
      ],
      transitionOut: CrossTransition(
        duration: Duration(seconds: 1),
        builder: CrossTransitions.fadeCross(),
      ),
      theme: ThemeConfig(
        builder: (context) => MyTheme(context),
        initTheme: ThemeData,
        themes: MyTheme.themes,
      ),
      initScreen: AppState.onboarding,
      screens: {
        AppState.onboarding: (_) => InitLoader.of(
              delay: Duration(seconds: 1),
              builder: (context) => Container(
                color: Colors.orange,
              ),
            ),
        AppState.main: (_) => MenuPage(),
      },
      app: (key, setup, home) => MaterialApp(
        key: key,
        home: home,
        theme: setup.theme,
        title: 'Flutter Example',
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

  static Map<dynamic, Initializer<ThemeData>> get themes => {
        ThemeData: (_) => ThemeData(
              primaryColor: Colors.deepOrange,
            ),
        Brightness.light: (_) => ThemeData.light().copyWith(primaryColor: Colors.green),
        Brightness.dark: (_) => ThemeData.dark().copyWith(primaryColor: Colors.lightGreenAccent),
      };
}
