import 'package:flutter_control/core.dart';

class AssetPath {
  const AssetPath();

  /// Refers to assets/path
  String root(String path) => path.startsWith('/') ? "assets$path" : "assets/$path";

  /// Refers to assets/images/name.ext
  /// Default [ext] is 'png'.
  String image(String name, [String ext = 'png']) => root("images/$name.$ext");

  /// Refers to assets/icons/name.ext
  /// Default [ext] is 'png'.
  String icon(String name, [String ext = 'png']) => root("icons/$name.$ext");

  /// Refers to assets/icons/name.svg
  String svg(String name) => root("icons/$name.svg");

  /// Refers to assets/data/name.ext
  String data(String name, String ext) => root("data/$name.$ext");

  /// Refers to assets/raw/name.ext
  String raw(String name, String ext) => root("raw/$name.$ext");

  /// Refers to assets/localization/name.ext
  /// Default [ext] is 'json'.
  String localization(String name, [String ext = 'json']) => root("localization/$name.$ext");
}

/// Wraps [ThemeData] and [Device] to provide more settings and custom properties that are more app design specific.
/// [ControlTheme] is build during [ControlBase] initialization.
///
class ControlTheme {
  static const root = 0;
  static const scope = 1;

  double get padding => 16.0;

  double get paddingHalf => 8.0;

  double get paddingQuad => 4.0;

  double get paddingQuarter => 12.0;

  double get paddingMid => 24.0;

  double get paddingExtended => 32.0;

  double get paddingSection => 64.0;

  double get paddingHead => 96.0;

  double get iconSize => 24.0;

  double get iconSizeLarge => 32.0;

  double get iconBounds => 48.0;

  double get iconLauncher => 144.0;

  double get thumb => 96.0;

  double get preview => 192.0;

  double get head => 320.0;

  double get buttonWidth => 256.0;

  double get buttonHeight => 56.0;

  double get buttonRadius => 28.0;

  double get buttonHeightSmall => 32.0;

  double get buttonRadiusSmall => 16.0;

  double get controlHeight => 42.0;

  double get inputHeight => 56.0;

  double get barHeight => 56.0;

  double get divider => 1.0;

  ////////////////////////////////////////////////////////////////////////////////

  String get fontName => 'GoogleSans';

  double get fontSize => 14.0;

  double get fontSizeSmall => 12.0;

  double get fontSizeMid => 18.0;

  double get fontSizeLarge => 24.0;

  double get fontSizeExtra => 28.0;

  double get fontSizeSuper => 36.0;

  ////////////////////////////////////////////////////////////////////////////////

  Duration get animDuration => const Duration(milliseconds: 250);

  Duration get animDurationFast => const Duration(milliseconds: 150);

  Duration get animDurationSlow => const Duration(milliseconds: 500);

  Duration get animDurationSecond => const Duration(milliseconds: 1000);

  ////////////////////////////////////////////////////////////////////////////////

  TextTheme get font => data.textTheme;

  TextTheme get fontPrimary => data.primaryTextTheme;

  TextTheme get fontAccent => data.accentTextTheme;

  Color get primaryColor => data.primaryColor;

  Color get primaryColorDark => data.primaryColorDark;

  Color get primaryColorLight => data.primaryColorLight;

  Color get accentColor => data.accentColor;

  ////////////////////////////////////////////////////////////////////////////////

  Size get toolbarAreaSize => Size(device.width, device.topBorderSize + barHeight);

  Size get menuAreaSize => Size(device.width, device.bottomBorderSize + barHeight);

  ////////////////////////////////////////////////////////////////////////////////

  final Device device;
  final ThemeData data;
  final AssetPath asset;

  const ControlTheme({this.device, this.data, this.asset: const AssetPath()});

  factory ControlTheme.of(BuildContext context) => ControlTheme(
        device: Device.of(context),
        data: Theme.of(context),
      );

  static TextTheme textTheme({
    String fontName,
    Color color,
    double fontSize,
    double fontSizeSmall,
    double fontSizeMid,
    double fontSizeLarge,
    double fontSizeExtra,
    double fontSizeSuper,
  }) =>
      TextTheme(
        display4: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeSuper, fontWeight: FontWeight.w900),
        display3: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeExtra, fontWeight: FontWeight.w700),
        display2: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeLarge, fontWeight: FontWeight.w600),
        display1: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeMid, fontWeight: FontWeight.w500),
        headline: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeLarge, fontWeight: FontWeight.w600),
        title: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeMid, fontWeight: FontWeight.w700),
        subhead: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeMid, fontWeight: FontWeight.w500),
        body2: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeSmall, fontWeight: FontWeight.w300),
        body1: TextStyle(fontFamily: fontName, color: color, fontSize: fontSize),
        caption: TextStyle(fontFamily: fontName, color: color, fontSize: fontSizeSmall, fontWeight: FontWeight.w300),
        button: TextStyle(fontFamily: fontName, color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
        subtitle: TextStyle(fontFamily: fontName, color: color, fontSize: fontSize, fontWeight: FontWeight.w300),
        overline: TextStyle(fontFamily: fontName, color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
      );
}

class ControlThemeScope<T extends ControlTheme> extends InheritedWidget {
  final T theme;

  const ControlThemeScope({Key key, @required this.theme, Widget child}) : super(key: key, child: child);

  static Theme build<T extends ControlTheme>({@required ThemeData data, @required Initializer<T> control}) {
    return Theme(
      data: data,
      child: Builder(builder: (context) => ControlThemeScope<T>(theme: control(context))),
    );
  }

  @override
  bool updateShouldNotify(ControlThemeScope oldWidget) {
    return theme != oldWidget.theme;
  }
}

mixin ThemeProvider<T extends ControlTheme> {
  static T of<T extends ControlTheme>() => ControlProvider.get<T>();

  static T scope<T extends ControlTheme>(BuildContext context) {
    final widget = context.inheritFromWidgetOfExactType(ControlThemeScope) as ControlThemeScope;

    return widget?.theme ?? of<T>();
  }

  /// Holds current [ControlTheme]. Ideally value is build once.
  /// Holder can be rebuild with [invalidateTheme].
  final _holder = InitHolder<T>();

  /// Instance of requested [ControlTheme].
  /// Override [themeScope] to receive correct [ThemeData].
  ///
  /// Custom [ControlTheme] builder can be set during [ControlBase] initialization.
  @protected
  T get theme => _holder.getWithBuilder(() => of<T>());

  /// Instance of [AssetPath].
  ///
  /// Custom [AssetPath] can be set to [ControlTheme] - [theme].
  @protected
  AssetPath get asset => theme?.asset;

  /// Instance of [Device].
  /// Wrapper of [MediaQuery].
  @protected
  Device get device => theme?.device;

  /// Instance of nearest [ThemeData].
  @protected
  ThemeData get themeData => theme?.data;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get font => themeData?.textTheme;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get fontPrimary => themeData?.primaryTextTheme;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get fontAccent => themeData?.accentTextTheme;

  /// Origin of [ControlTheme].
  /// [ControlTheme.scope] initializes with nearest [ThemeData].
  /// [ControlTheme.root] initializes with root [ThemeData] - default.
  ///
  /// Custom [ControlTheme] builder can be set during [ControlBase] initialization.
  int get themeScope => ControlTheme.root;

  /// Invalidates current [ControlTheme].
  /// With [ControlWidget] checks [themeScope] to gather correct [ThemeData]. Scope: [ControlTheme.root] / [ControlTheme.scope].
  /// With other objects checks [context] to provide scoped or global [ThemeData].
  void invalidateTheme({BuildContext context}) {
    if (context != null && themeScope == ControlTheme.scope) {
      _holder.set(builder: () => scope<T>(context), override: true);
    } else {
      _holder.set(builder: () => of<T>(), override: true);
    }
  }
}
