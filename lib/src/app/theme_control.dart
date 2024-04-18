part of flutter_control;

typedef ThemeInitializer = ThemeData Function();
typedef ThemeFactory = Map<dynamic, ThemeInitializer>;

class ThemeConfig extends ValueNotifier<ThemeData> with PrefsProvider {
  static const preference_key = 'control_theme';

  static String get preferredTheme => PrefsProvider.instance.get(ThemeConfig.preference_key, defaultValue: 'auto')!;

  static Brightness get platformBrightness => PlatformDispatcher.instance.platformBrightness;

  final dynamic initial;
  final ThemeFactory themes;

  ThemeConfig({
    this.initial,
    required this.themes,
  }) : super(themes[initial ?? themes.keys.first]!());

  Future<void> mount() async {
    await prefs.mount();
    changeTheme(preferredTheme, false);
  }

  ThemeData getTheme(dynamic key) {
    key = Parse.name(key);

    key = themes.keys.firstWhere((item) => Parse.name(item) == key, orElse: () => initial ?? platformBrightness) ;

    if (themes.containsKey(key)) {
      return themes[key]!();
    }

    return themes.values.first();
  }

  void setAsPreferred(dynamic key) => prefs.set(ThemeConfig.preference_key, Parse.name(key));

  void resetPreferred() => prefs.set(ThemeConfig.preference_key, null);

  bool isPreferred(dynamic key) => preferredTheme == Parse.name(key);

  void changeTheme(dynamic key, [bool preferred = true]) {
    final data = getTheme(key);

    if (preferred) {
      setAsPreferred(key);
    }

    value = data;
  }
}
