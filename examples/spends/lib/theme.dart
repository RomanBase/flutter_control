import 'package:flutter_control/core.dart';

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
        subtitle: TextStyle(color: colorB, fontWeight: FontWeight.w300, fontSize: 14.0, letterSpacing: 1.5),
        body1: TextStyle(color: colorA, fontSize: 14.0),
        body2: TextStyle(color: colorB, fontWeight: FontWeight.w300, fontSize: 12.0),
        button: TextStyle(color: colorA, fontWeight: FontWeight.w700),
      );
}
