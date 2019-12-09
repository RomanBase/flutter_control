import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';

import 'cards_controller.dart';
import 'menu_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget with LocalizationProvider {
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
      theme: (context) => MyTheme.of(context),
      root: (context) => MenuPage(),
      app: (BuildContext context, Key key, Widget home) {
        return MaterialApp(
          key: key,
          home: home,
          title: localization.isActive ? localize('app_name') : 'Flutter Example',
          theme: ThemeData(
            primaryColor: Colors.orange,
          ),
        );
      },
    );
  }
}

class MyTheme extends ControlTheme {
  @override
  double get padding => 24.0;

  @override
  double get paddingHalf => 12.0;

  Color get superColor => Colors.red;

  const MyTheme(Device device, ThemeData data) : super(device: device, data: data);

  factory MyTheme.of(BuildContext context) {
    return MyTheme(Device.of(context), Theme.of(context));
  }
}
