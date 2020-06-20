import 'package:flutter_control/core.dart';

class SettingsController extends BaseControl with LocalizationProvider, PrefsProvider, ThemeProvider {
  final localizationLoading = LoadingControl();

  void changeLocaleToEN() => changeLocale('en_US');

  void changeLocaleToCS() => changeLocale('cs_CZ');

  Future<void> changeLocale(String locale) async {
    localizationLoading.progress();

    await localization.changeLocale(locale);

    localizationLoading.done();
  }

  void toggleTheme() async {
    invalidateTheme();

    final currentTheme = theme.config.preferredThemeName;

    printDebug(currentTheme);

    if (currentTheme == Parse.name(ThemeData)) {
      theme.changeTheme(Brightness.light);
    } else if (currentTheme == Parse.name(Brightness.light)) {
      theme.changeTheme(Brightness.dark);
    } else if (currentTheme == Parse.name(Brightness.dark)) {
      theme.changeTheme(Brightness.light);
    }
  }

  void unloadApp() {
    Control.root().setOnboardingState();
  }
}
