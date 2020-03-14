import 'package:flutter_control/core.dart';

class SpendTheme extends ControlTheme {
  final dark = Color(0xFF353535);
  final gray = Color(0xFFB3B3B3);
  final lightGray = Color(0xFFECECEC);
  final white = Color(0xFFFAFAFA);

  final red = Color(0xEEAA0000);
  final yellow = Color(0xFFFFCC00);

  final green = Color(0xFF006560);
  final blue = Color(0xFF006065);
  final lightGreen = Color(0xFF00A175);

  List<Color> get gradient => [green, blue, lightGreen];

  SpendTheme([BuildContext context]) : super(context);

  ThemeData get darkTheme => ThemeData(
        primaryColor: green,
        primaryColorLight: lightGreen,
        primaryColorDark: blue,
        accentColor: lightGreen,
        canvasColor: dark,
        indicatorColor: white,
        fontFamily: 'Oswald',
        textTheme: buildTextTheme(
          lightGray,
          gray,
        ),
      );

  ThemeData get lightTheme => ThemeData(
        primaryColor: blue,
        primaryColorLight: green,
        primaryColorDark: green,
        accentColor: lightGreen,
        canvasColor: lightGray,
        fontFamily: 'Oswald',
        textTheme: buildTextTheme(
          dark,
          gray,
        ),
      );

  TextTheme buildTextTheme(Color colorA, Color colorB) => TextTheme(
        subtitle: TextStyle(color: colorB, fontWeight: FontWeight.w300, fontSize: 14.0, letterSpacing: 1.5),
        body1: TextStyle(color: colorA, fontSize: 14.0),
        body2: TextStyle(color: colorB, fontWeight: FontWeight.w300, fontSize: 12.0),
        button: TextStyle(color: colorA, fontWeight: FontWeight.w700),
      );
}
