part of flutter_control;

typedef ThemeInitializer = ThemeData Function();

class ThemeConfig with PrefsProvider, ChangeNotifier {
  static const preference_key = 'control_theme';

  static String get preferredTheme => PrefsProvider.instance.get(ThemeConfig.preference_key, defaultValue: 'auto')!;

  static Brightness get platformBrightness => PlatformDispatcher.instance.platformBrightness;

  final dynamic initTheme;
  final Map<dynamic, ThemeInitializer> themes;

  ThemeConfig({
    this.initTheme,
    required this.themes,
  });

  bool contains(dynamic key) {
    key = Parse.name(key);

    return themes.keys.firstWhere((item) => Parse.name(item) == key, orElse: () => null) != null;
  }

  ThemeData getTheme(dynamic key) {
    key = Parse.name(key);

    key = themes.keys.firstWhere((item) => Parse.name(item) == key, orElse: () => initTheme ?? platformBrightness);

    if (themes.containsKey(key)) {
      return themes[key]!();
    }

    return themes.values.first();
  }

  ThemeData getInitTheme() => getTheme(initTheme);

  ThemeData getPreferredTheme() => getTheme(preferredTheme);

  void setAsPreferred(dynamic key) => prefs.set(ThemeConfig.preference_key, Parse.name(key));

  void resetPreferred() => prefs.set(ThemeConfig.preference_key, null);

  bool isPreferred(dynamic key) => preferredTheme == Parse.name(key);

  void changeTheme(dynamic key, [bool preferred = true]) {
    final data = getTheme(key);

    if (preferred) {
      setAsPreferred(key);
    }

    notifyListeners();
    broadcastTheme(data);
  }

  void broadcastTheme(ThemeData data) => BroadcastProvider.broadcast<ThemeData>(value: data);
}
