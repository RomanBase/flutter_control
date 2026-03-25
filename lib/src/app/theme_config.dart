part of '../../control.dart';

/// A function that returns a theme of type [T].
typedef ThemeInitializer<T> = T Function();

/// A map of theme keys to their corresponding [ThemeInitializer].
typedef ThemeFactory<T> = Map<dynamic, ThemeInitializer<T>>;

/// A [ThemeFactory] for [ThemeData].
typedef MaterialThemeFactory = ThemeFactory<ThemeData>;

/// A [ThemeFactory] for [CupertinoThemeData].
typedef CupertinoThemeFactory = ThemeFactory<CupertinoThemeData>;

/// A concrete implementation of [ThemeConfig] for [ThemeData].
class MaterialThemeConfig extends ThemeConfig<ThemeData> {
  MaterialThemeConfig({
    super.initial,
    required super.themes,
  });
}

/// A concrete implementation of [ThemeConfig] for [CupertinoThemeData].
class CupertinoThemeConfig extends ThemeConfig<CupertinoThemeData> {
  CupertinoThemeConfig({
    super.initial,
    required super.themes,
  });
}

/// Manages theme data and preferences for the application.
/// It can be used to switch between different themes and persist the user's choice.
class ThemeConfig<T> extends ValueNotifier<T> with PrefsProvider {
  /// The key used to store the preferred theme in shared preferences.
  static const preference_key = 'control_theme';

  /// Returns the user's preferred theme key from shared preferences.
  /// Defaults to 'auto' if no preference is found.
  static String get preferredTheme => PrefsProvider.instance
      .get(ThemeConfig.preference_key, defaultValue: 'auto')!;

  /// Returns the current brightness of the platform (light or dark).
  static Brightness get platformBrightness =>
      PlatformDispatcher.instance.platformBrightness;

  /// The key of the initial theme to use.
  final dynamic initial;

  /// The factory containing all available themes.
  final ThemeFactory themes;

  dynamic _current;

  /// Returns the key of the current active theme.
  dynamic get currentTheme => _current ?? preferredTheme;

  ThemeConfig({
    this.initial,
    required this.themes,
  }) : super(themes[initial ?? themes.keys.first]!());

  /// Mounts the theme configuration, loading preferences and setting the initial theme.
  Future<void> mount() async {
    await prefs.mount();
    changeTheme(preferredTheme, false);
  }

  /// Retrieves a theme object by its [key].
  /// [key] - The key identifying the theme.
  T getTheme(dynamic key) {
    key = Parse.name(key);

    key = themes.keys.firstWhere((item) => Parse.name(item) == key,
        orElse: () => initial ?? platformBrightness);

    if (themes.containsKey(key)) {
      return themes[key]!();
    }

    return themes.values.first();
  }

  /// Sets the given theme [key] as the user's preferred theme.
  void setAsPreferred(dynamic key) =>
      prefs.set(ThemeConfig.preference_key, Parse.name(key));

  /// Resets the user's preferred theme to the default.
  void resetPreferred() => prefs.set(ThemeConfig.preference_key, null);

  /// Checks if the given theme [key] is currently set as the preferred theme.
  bool isPreferred(dynamic key) => preferredTheme == Parse.name(key);

  /// Changes the current theme to the one identified by [key].
  /// [key] - The key of the new theme.
  /// [preferred] - If true, saves this theme as the user's preferred theme.
  bool changeTheme(dynamic key, [bool preferred = true]) {
    _current = key;
    final data = getTheme(key);

    if (preferred) {
      setAsPreferred(key);
    }

    value = data;

    return true;
  }
}
