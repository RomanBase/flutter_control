import 'package:flutter_control/control.dart';

class UISize {
  const UISize._();

  static const quad = 4.0;
  static const half = 8.0;
  static const quarter = 12.0;
  static const full = 16.0;
  static const mid = 24.0;
  static const extra = 32.0;
  static const bounds = 48.0;
  static const section = 64.0;

  static const iconSmall = 18.0;
  static const icon = 24.0;
  static const iconLarge = 32.0;
  static const iconBounds = 48.0;
  static const iconLauncher = 144.0;

  static const control = 42.0;
  static const barHeight = 56.0;
  static const buttonHeight = 56.0;

  static const thumb = 96.0;
  static const preview = 192.0;
  static const head = 420.0;
  static const headPreview = 240.0;

  static const divider = 1.0;

  static const itemRadius = 12.0;
  static const cardRadius = 24.0;
  static const actionScaleRatio = 0.95;
}

const _fontFamily = 'Nunito';
const _fontHeadlineFamily = 'Thicker';

const _fontSpacing = 0.25;
const _fontHeadlineSpacing = 0.0;

const _fontHeight = 1.35;
const _fontContentHeight = 1.6;
const _fontHeadlineHeight = 1.1;

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  surface: Colors.white,
  onSurface: Colors.black,
  background: Colors.white,
  onBackground: Colors.black,
  primary: Color(0xFF8BCC00),
  primaryContainer: Color(0xFFB5F4D7),
  onPrimary: Colors.white,
  secondary: Color(0xFF032045),
  secondaryContainer: Color(0xFFE8EAF3),
  onSecondary: Colors.white,
  onSecondaryContainer: Color(0xFF8C9FB8),
  tertiary: Color(0xFFA3AAB7),
  tertiaryContainer: Color(0x25A3AAB7),
  onTertiary: Colors.black,
  error: Color(0xFFE60005),
  errorContainer: Color(0x50E60005),
  onError: Colors.white,
  shadow: Color(0x338DCFE8),
  outline: Color(0xFFEAEDF3),
  outlineVariant: Color(0xFFA3AAB7),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  surface: Colors.black,
  onSurface: Colors.white,
  background: Colors.black,
  onBackground: Colors.white,
  primary: Color(0xFF8BCC00),
  primaryContainer: Color(0xFFB5F4D7),
  onPrimary: Colors.white,
  secondary: Color(0xFF032045),
  secondaryContainer: Color(0xFFE8EAF3),
  onSecondary: Colors.white,
  onSecondaryContainer: Color(0xFF8C9FB8),
  tertiary: Color(0xFFA3AAB7),
  tertiaryContainer: Color(0x25A3AAB7),
  onTertiary: Colors.black,
  error: Color(0xFFE60005),
  errorContainer: Color(0x50E60005),
  onError: Colors.white,
  shadow: Color(0x338DCFE8),
  outline: Color(0xFFEAEDF3),
  outlineVariant: Color(0xFFA3AAB7),
);

TextTheme _textTheme(Color color) => TextTheme(
      displayLarge: TextStyle(fontSize: 48.0, color: color, fontFamily: _fontHeadlineFamily, fontWeight: FontWeight.w900, height: _fontHeadlineHeight, letterSpacing: _fontHeadlineSpacing),
      displayMedium: TextStyle(fontSize: 40.0, color: color, fontFamily: _fontHeadlineFamily, fontWeight: FontWeight.w900, height: _fontHeadlineHeight, letterSpacing: _fontHeadlineSpacing),
      displaySmall: TextStyle(fontSize: 32.0, color: color, fontFamily: _fontHeadlineFamily, fontWeight: FontWeight.w900, height: _fontHeadlineHeight, letterSpacing: _fontHeadlineSpacing),
      headlineLarge: TextStyle(fontSize: 28.0, color: color, fontFamily: _fontHeadlineFamily, fontWeight: FontWeight.w900, height: _fontHeadlineHeight, letterSpacing: _fontHeadlineSpacing),
      headlineMedium: TextStyle(fontSize: 24.0, color: color, fontFamily: _fontHeadlineFamily, fontWeight: FontWeight.w900, height: _fontHeadlineHeight, letterSpacing: _fontHeadlineSpacing),
      headlineSmall: TextStyle(fontSize: 20.0, color: color, fontFamily: _fontHeadlineFamily, fontWeight: FontWeight.w900, height: _fontHeadlineHeight, letterSpacing: _fontHeadlineSpacing),
      titleLarge: TextStyle(fontSize: 22.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w800, height: _fontHeight, letterSpacing: _fontSpacing),
      titleMedium: TextStyle(fontSize: 18.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w800, height: _fontHeight, letterSpacing: _fontSpacing),
      titleSmall: TextStyle(fontSize: 16.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w700, height: _fontHeight, letterSpacing: _fontSpacing),
      bodyLarge: TextStyle(fontSize: 14.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w400, height: _fontContentHeight, letterSpacing: _fontSpacing),
      bodyMedium: TextStyle(fontSize: 13.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w400, height: _fontContentHeight, letterSpacing: _fontSpacing),
      bodySmall: TextStyle(fontSize: 12.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w300, height: _fontContentHeight, letterSpacing: _fontSpacing),
      labelLarge: TextStyle(fontSize: 15.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w700, height: _fontHeight, letterSpacing: _fontSpacing),
      labelMedium: TextStyle(fontSize: 14.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w700, height: _fontContentHeight, letterSpacing: _fontSpacing),
      labelSmall: TextStyle(fontSize: 12.0, color: color, fontFamily: _fontFamily, fontWeight: FontWeight.w700, height: _fontContentHeight, letterSpacing: _fontSpacing),
    );

ThemeData _light() => ThemeData.from(
      useMaterial3: true,
      colorScheme: _lightScheme,
      textTheme: _textTheme(_lightScheme.secondary),
    ).copyWith(
      primaryColorLight: Color(0xFF97C005),
      primaryColorDark: Color(0xFF97C005),
      primaryTextTheme: _textTheme(_lightScheme.primary),
      dividerColor: Color(0xFFEAEDF3),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(
          color: _lightScheme.secondary.withOpacity(0.5),
        ),
      ),
    );

ThemeData _dark() => ThemeData.from(
      useMaterial3: true,
      colorScheme: _darkScheme,
      textTheme: _textTheme(_darkScheme.secondary),
    ).copyWith(
      primaryColorLight: Color(0xFF97C005),
      primaryColorDark: Color(0xFF97C005),
      primaryTextTheme: _textTheme(_darkScheme.primary),
      dividerColor: Color(0xFFEAEDF3),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(
          color: _darkScheme.secondary.withOpacity(0.5),
        ),
      ),
    );

class UITheme {
  const UITheme._();

  static ColorScheme scheme = _lightScheme;

  static ThemeFactory get config => {
        Brightness.light: () => _light(),
        Brightness.dark: () => _dark(),
      };
}

extension ThemeDataExt on ThemeData {
  static const List<Color> shadowGradient = [
    Color(0x75000000),
    Color(0x00000000),
  ];

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          offset: Offset(0.0, 1.0),
          color: colorScheme.shadow,
          blurRadius: 8.0,
          spreadRadius: 4.0,
        ),
      ];

  ScrollPhysics get platformPhysics => Device.onPlatform(
        android: () => BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        ios: () => BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        other: () => BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      )!;
}

extension TextStyleExtension on TextStyle {
  TextStyle get onBackground => copyWith(color: UITheme.scheme.onBackground);

  TextStyle get onPrimary => copyWith(color: UITheme.scheme.onPrimary);

  TextStyle get onSecondary => copyWith(color: UITheme.scheme.onSecondary);

  TextStyle get onTertiary => copyWith(color: UITheme.scheme.onTertiary);

  TextStyle get onError => copyWith(color: UITheme.scheme.onError);

  TextStyle get primary => copyWith(color: UITheme.scheme.primary);

  TextStyle get secondary => copyWith(color: UITheme.scheme.secondary);

  TextStyle get tertiary => copyWith(color: UITheme.scheme.tertiary);

  TextStyle get error => copyWith(color: UITheme.scheme.error);

  TextStyle get onSurfaceVariant => copyWith(color: UITheme.scheme.onSurfaceVariant);

  TextStyle get asOutline => copyWith(color: UITheme.scheme.outline);

  TextStyle get asOutlineVariant => copyWith(color: UITheme.scheme.outlineVariant);

  TextStyle withOpacity(double opacity) => copyWith(color: color?.withOpacity(opacity));
}

extension ButtonStyleExtension on ButtonStyle {
  ButtonStyle get outline => this.copyWith(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.transparent),
        surfaceTintColor: MaterialStatePropertyAll<Color>(backgroundColor?.resolve({}) ?? UITheme.scheme.primary),
        overlayColor: MaterialStatePropertyAll<Color>((backgroundColor?.resolve({}) ?? UITheme.scheme.primary).withOpacity(0.25)),
        shadowColor: MaterialStatePropertyAll<Color>(Colors.transparent),
        shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            side: BorderSide(color: backgroundColor?.resolve({}) ?? UITheme.scheme.primary),
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
      );

  ButtonStyle get error => this.copyWith(
        backgroundColor: MaterialStatePropertyAll<Color>(UITheme.scheme.error),
        overlayColor: MaterialStatePropertyAll<Color>((UITheme.scheme.onError).withOpacity(0.25)),
      );
}
