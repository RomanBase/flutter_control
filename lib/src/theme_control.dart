import 'package:flutter_control/core.dart';

class AssetPath {
  final String rootDir;

  const AssetPath({this.rootDir: 'assets'});

  /// Refers to assets/path
  String root(String path) => path.startsWith('/') ? "$rootDir$path" : "$rootDir/$path";

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

  final padding = 16.0;

  final paddingHalf = 8.0;

  final paddingQuad = 4.0;

  final paddingQuarter = 12.0;

  final paddingMid = 24.0;

  final paddingExtended = 32.0;

  final paddingSection = 64.0;

  final paddingHead = 96.0;

  final iconSize = 24.0;

  final iconSizeLarge = 32.0;

  final iconBounds = 48.0;

  final iconLauncher = 144.0;

  final thumb = 96.0;

  final preview = 192.0;

  final head = 320.0;

  final buttonWidth = 256.0;

  final buttonHeight = 56.0;

  final buttonRadius = 28.0;

  final buttonHeightSmall = 32.0;

  final buttonRadiusSmall = 16.0;

  final controlHeight = 42.0;

  final inputHeight = 56.0;

  final barHeight = 56.0;

  final divider = 1.0;

  ////////////////////////////////////////////////////////////////////////////////

  final fontName = 'GoogleSans';

  final fontSize = 14.0;

  final fontSizeSmall = 12.0;

  final fontSizeMid = 18.0;

  final fontSizeLarge = 24.0;

  final fontSizeExtra = 28.0;

  final fontSizeSuper = 36.0;

  ////////////////////////////////////////////////////////////////////////////////

  final animDuration = const Duration(milliseconds: 250);

  final animDurationFast = const Duration(milliseconds: 150);

  final animDurationSlow = const Duration(milliseconds: 500);

  final animDurationSecond = const Duration(milliseconds: 1000);

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

  const ControlTheme(this.device, this.data, [this.asset = const AssetPath()]);

  factory ControlTheme.of(BuildContext context) => ControlTheme(
        Device.of(context),
        Theme.of(context),
      );

  ControlTheme copyWith({ThemeData data, AssetPath asset}) => ControlTheme(
        device,
        data ?? this.data,
        asset ?? this.asset,
      );

  @override
  bool operator ==(other) {
    return other is ControlTheme && data == other.data && this.runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => data.hashCode;
}

mixin ThemeProvider<T extends ControlTheme> {
  static T of<T extends ControlTheme>([BuildContext context]) => ControlProvider.init<ControlTheme>(context);

  /// Holds current [ControlTheme]. Ideally value is build once.
  /// Holder can be rebuild with [invalidateTheme].
  final _holder = InitHolder<T>(builder: () => of<T>());

  /// Instance of requested [ControlTheme].
  /// Override [themeScope] to receive correct [ThemeData].
  ///
  /// Custom [ControlTheme] builder can be set during [ControlBase] initialization.
  @protected
  T get theme => _holder.get();

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
  ThemeData get data => theme?.data;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get font => data?.textTheme;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get fontPrimary => data?.primaryTextTheme;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get fontAccent => data?.accentTextTheme;

  /// Origin of [ControlTheme].
  /// [ControlTheme.scope] initializes with nearest [ThemeData].
  /// [ControlTheme.root] initializes with root [ThemeData] - default.
  ///
  /// Custom [ControlTheme] builder can be set during [ControlBase] initialization.
  int get themeScope => ControlTheme.scope;

  /// Invalidates current [ControlTheme].
  /// With [ControlWidget] checks [themeScope] to gather correct [ThemeData]. Scope: [ControlTheme.root] / [ControlTheme.scope].
  /// With other objects checks [context] to provide scoped or global [ThemeData].
  void invalidateTheme([BuildContext context]) {
    _holder.set(builder: () => of<T>(context != null && themeScope == ControlTheme.scope ? context : null), override: true);
  }
}
