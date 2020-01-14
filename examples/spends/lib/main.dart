import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';
import 'package:spends/control/spend_control.dart';
import 'package:spends/data/spend_repo.dart';
import 'package:spends/fire/fire_spend.dart';
import 'package:spends/page/init_page.dart';
import 'package:spends/page/spend_list_page.dart';

import 'control/init_control.dart';
import 'control/spend_item_control.dart';
import 'fire/fire_control.dart';
import 'page/spend_item_dialog.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      locales: {
        'en': 'assets/localization/en.json',
      },
      entries: {
        FireControl: FireControl(),
        SpendControl: SpendControl(),
      },
      initializers: {
        SpendItemControl: (_) => SpendItemControl(),
        InitLoaderControl: (_) => InitControl(),
        SpendRepo: (_) => FireSpendRepo(),
      },
      routes: [
        ControlRoute.build<SpendItemDialog>(builder: (_) => SpendItemDialog()),
      ],
      theme: (context) => SpendTheme(context),
      loader: (_) => InitLoader(
        builder: (_) => InitPage(),
      ),
      root: (_, args) => SpendListPage(),
      app: (context, key, home) => MaterialApp(
        debugShowCheckedModeBanner: false,
        key: key,
        home: home,
        title: 'Spend List',
        theme: SpendTheme().darkTheme,
      ),
    );
  }
}

class SpendTheme extends ControlTheme {
  final dark = Color(0xFF454545);
  final gray = Color(0xFFB3B3B3);
  final lightGray = Color(0xFFECECEC);
  final white = Color(0xFFFAFAFA);

  final red = Color(0xFFCE0000);
  final yellow = Color(0xFFFFCC00);

  final blue = Color(0xFF00A1A7);
  final darkBlue = Color(0xFF017677);
  final green = Color(0xFF00A886);

  List<Color> get gradient => [blue, darkBlue, green];

  SpendTheme([BuildContext context]) : super(context);

  ThemeData get darkTheme => ThemeData(
        primaryColor: darkBlue,
        primaryColorLight: blue,
        primaryColorDark: darkBlue,
        accentColor: green,
        canvasColor: dark,
        indicatorColor: white,
        fontFamily: 'Oswald',
        textTheme: buildTextTheme(
          lightGray,
          gray,
        ),
      );

  ThemeData get lightTheme => ThemeData(
        primaryColor: darkBlue,
        primaryColorLight: blue,
        primaryColorDark: darkBlue,
        accentColor: green,
        canvasColor: lightGray,
        fontFamily: 'Oswald',
        textTheme: buildTextTheme(
          dark,
          gray,
        ),
      );

  TextTheme buildTextTheme(Color colorA, Color colorB) => TextTheme(
        title: TextStyle(color: colorA, fontWeight: FontWeight.w500, fontSize: 64.0, letterSpacing: 7.5),
        subtitle: TextStyle(color: colorB, fontWeight: FontWeight.w300, fontSize: 14.0, letterSpacing: 1.5),
        body1: TextStyle(color: colorA, fontSize: 14.0),
        body2: TextStyle(color: colorB, fontWeight: FontWeight.w300, fontSize: 12.0),
        button: TextStyle(color: colorA, fontWeight: FontWeight.w700),
      );
}
