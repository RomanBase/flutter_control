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

  ////////////////////////////////////////////////////////////////////////////////

  Duration get anim_duration => const Duration(milliseconds: 250);

  Duration get anim_duration_fast => const Duration(milliseconds: 150);

  Duration get anim_duration_slow => const Duration(milliseconds: 500);

  Duration get anim_duration_second => const Duration(milliseconds: 1000);

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
}
