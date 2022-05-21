import 'package:flutter_control/control.dart';

class SettingsController extends BaseControl
    with LocalinoProvider, PrefsProvider, ThemeProvider {
  final localizationLoading = LoadingControl();

  void changeLocaleToEN() => changeLocale('en_US');

  void changeLocaleToCS() => changeLocale('cs_CZ');

  Future<void> changeLocale(String locale) async {
    localizationLoading.progress();

    await localization.changeLocale(locale);

    localizationLoading.done();
  }

  void toggleTheme() async {
    invalidateTheme(ControlScope.root.context);

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
    ControlScope.root.setOnboardingState();
  }

  void swapApp() {
    if (ControlScope.root.setup.state == AppState.auth) {
      ControlScope.root.setMainState();
    } else {
      ControlScope.root.setAuthState();
    }
  }
}
