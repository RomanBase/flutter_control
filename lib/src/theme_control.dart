import 'package:flutter/scheduler.dart';
import 'package:flutter_control/core.dart';

class AssetPath {
  final String rootDir;

  const AssetPath({this.rootDir: 'assets'});

  /// Refers to assets/path
  String root(String path) =>
      path.startsWith('/') ? "$rootDir$path" : "$rootDir/$path";

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
  String localization(String name, [String ext = 'json']) =>
      root("localization/$name.$ext");
}

/// Wraps [ThemeData] and [Device] to provide more settings and custom properties that are more app design specific.
/// [ControlTheme] is build during [ControlRoot] initialization.
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

  final iconSizeSmall = 18.0;

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

  ////////////////////////////////////////////////////////////////////////////////

  final animDuration = const Duration(milliseconds: 250);

  final animDurationFast = const Duration(milliseconds: 150);

  final animDurationSlow = const Duration(milliseconds: 500);

  final animDurationSecond = const Duration(milliseconds: 1000);

  final animTransition = const Duration(milliseconds: 300);

  ////////////////////////////////////////////////////////////////////////////////

  TextTheme get font => data.textTheme;

  TextTheme get fontPrimary => data.primaryTextTheme;

  TextTheme get fontAccent => data.accentTextTheme;

  Color get primaryColor => data.primaryColor;

  Color get primaryColorDark => data.primaryColorDark;

  Color get primaryColorLight => data.primaryColorLight;

  Color get accentColorLight => data.accentColor.withOpacity(0.5);

  Color get accentColor => data.accentColor;

  Color get accentColorDark => data.accentColor;

  Color get tintColor => data.accentColor;

  Color get backgroundColor => data.backgroundColor;

  Color get errorColor => data.errorColor;

  Color get activeColor => data.toggleableActiveColor;

  ////////////////////////////////////////////////////////////////////////////////

  Size get toolbarAreaSize =>
      Size(device.width, device.topBorderSize + barHeight);

  Size get menuAreaSize =>
      Size(device.width, device.bottomBorderSize + barHeight);

  ////////////////////////////////////////////////////////////////////////////////

  BuildContext _context;
  Device _device;
  ThemeData _data;
  AssetPath _asset;

  @protected
  BuildContext get context => _context;

  Device get device => _device ?? (_device = Device.of(_context));

  ThemeData get data => _data ?? (_data = Theme.of(_context));

  AssetPath get assets => _asset ?? (_asset = AssetPath());

  @protected
  set assets(AssetPath value) => _asset = value;

  @protected
  set data(ThemeData value) => _data = value;

  @protected
  set device(Device value) => _device = value;

  ThemeConfig config;

  ControlTheme(this._context);

  void invalidate([BuildContext context]) {
    _data = null;
    _device = null;
    _context = context ?? Control.scope?.context;

    assert(_context != null);
  }

  static BroadcastSubscription<ControlTheme> subscribeChanges(
      ValueCallback<ControlTheme> callback) {
    return BroadcastProvider.subscribe<ControlTheme>(ControlTheme, callback);
  }

  Future<void> resetPreferredTheme({bool loadSystemTheme: false}) async {
    config.resetPreferred();

    if (loadSystemTheme) {
      return setSystemTheme();
    }
  }

  void setDefaultTheme() => data = config.getCurrentTheme(this);

  ControlTheme setSystemTheme() => pushTheme(config.getSystemTheme(this));

  ControlTheme changeTheme(dynamic key, {bool preferred: true}) {
    if (config.contains(key)) {
      config = config.copyWith(theme: key);
      final theme = config.getCurrentTheme(this);

      if (preferred) {
        config.setAsPreferred();
      }

      return pushTheme(theme);
    }

    return this;
  }

  ControlTheme pushTheme(ThemeData theme) {
    if (theme != data) {
      data = theme;
      BroadcastProvider.broadcast<ControlTheme>(value: this);
    }

    return this;
  }

  @override
  bool operator ==(other) {
    return other is ControlTheme &&
        data == other.data &&
        this.runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => data.hashCode;
}

typedef ThemeInitializer<T extends ControlTheme> = ThemeData Function(
    T control);

class ThemeConfig<T extends ControlTheme> {
  static const preference_key = 'control_theme';

  final Initializer<T> builder;
  final dynamic initTheme;
  final Map<dynamic, ThemeInitializer<T>> themes;

  Initializer get _defaultBuilder => (context) => ControlTheme(context);

  Initializer<T> get initializer =>
      (context) => (builder ?? _defaultBuilder)(context)..config = this;

  String get preferredThemeName => Control.get<BasePrefs>()
      .get(ThemeConfig.preference_key, defaultValue: Parse.name(initTheme));

  static Brightness get platformBrightness =>
      SchedulerBinding.instance.window.platformBrightness;

  /// [builder] - Initializer of [ControlTheme]. Set this initializer only if providing custom, extended version of [ControlTheme].
  const ThemeConfig({
    this.builder,
    this.initTheme,
    @required this.themes,
  }) : assert(themes != null);

  bool contains(dynamic key) {
    key = Parse.name(key);

    return themes.keys.firstWhere((item) => Parse.name(item) == key,
            orElse: () => null) !=
        null;
  }

  ThemeData getTheme(dynamic key, T control) {
    key = Parse.name(key);

    key = themes.keys
        .firstWhere((item) => Parse.name(item) == key, orElse: () => initTheme);

    if (themes.containsKey(key)) {
      return themes[key](control);
    }

    return themes.values.first(control);
  }

  ThemeData getCurrentTheme(T control) => getTheme(initTheme, control);

  ThemeData getSystemTheme(T control) => getTheme(preferredThemeName, control);

  void setAsPreferred() => Control.get<BasePrefs>()
      .set(ThemeConfig.preference_key, Parse.name(initTheme));

  void resetPreferred() =>
      Control.get<BasePrefs>().set(ThemeConfig.preference_key, null);

  U getPreferredKey<U>([dynamic enums]) {
    final dynamic key =
        Control.get<BasePrefs>().get(ThemeConfig.preference_key);

    if (enums != null) {
      return Parse.toEnum(key, enums);
    }

    return key;
  }

  bool isPreferred(dynamic key) => preferredThemeName == Parse.name(key);

  ThemeConfig copyWith({
    dynamic theme,
  }) =>
      ThemeConfig(
        builder: this.builder,
        initTheme: theme ?? this.initTheme,
        themes: this.themes,
      );
}

mixin ThemeProvider<T extends ControlTheme> {
  static T of<T extends ControlTheme>([BuildContext context]) =>
      Control.init<ControlTheme>(context);

  /// Instance of requested [ControlTheme].
  /// Override [themeScope] to receive correct [ThemeData].
  ///
  /// Custom [ControlTheme] builder can be set during [ControlRoot] initialization.
  @protected
  final T theme = of<T>();

  /// Instance of [AssetPath].
  ///
  /// Custom [AssetPath] can be set to [ControlTheme].
  @protected
  AssetPath get asset => theme.assets;

  /// Instance of [Device].
  /// Wrapper of [MediaQuery].
  @protected
  Device get device => theme.device;

  /// Instance of nearest [ThemeData].
  @protected
  ThemeData get themeData => theme.data;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get font => theme.font;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get fontPrimary => theme.fontPrimary;

  /// Instance of nearest [TextTheme].
  @protected
  TextTheme get fontAccent => theme.fontAccent;

  /// Origin of [ControlTheme].
  /// [ControlTheme.scope] initializes with nearest [ThemeData].
  /// [ControlTheme.root] initializes with root [ThemeData] - default.
  ///
  /// Custom [ControlTheme] builder can be set during [ControlRoot] initialization.
  int get themeScope => ControlTheme.scope;

  /// Invalidates current [ControlTheme].
  /// Override [themeScope] to gather correct [ThemeData]. Scope: [ControlTheme.root] / [ControlTheme.scope].
  void invalidateTheme([BuildContext context]) {
    theme?.invalidate(
        context != null && themeScope == ControlTheme.scope ? context : null);
  }
}
