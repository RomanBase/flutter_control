import 'package:flutter_control/core.dart';

class SettingsController extends BaseControl with LocalizationProvider, PrefsProvider, ThemeProvider {
  final localizationLoading = LoadingControl();

  void changeLocaleToEN() => changeLocale('en_US');

  void changeLocaleToCS() => changeLocale('cs_CZ');

  Future<void> changeLocale(String locale) async {
    localizationLoading.progress();

    await localization.changeLocale(locale).then((args) {
      if (args.changed) {
        factory.get<ControlScope>().notifyControlState();
      }
    });

    localizationLoading.done();
  }

  void toggleTheme() async {
    //final theme = ThemeProvider.of();

    invalidateTheme();

    ThemeData data = theme.primaryColor != Colors.orange
        ? ThemeData(
            primaryColor: Colors.orange,
          )
        : ThemeData(
            primaryColor: Colors.green,
          );

    BroadcastProvider.broadcast('theme', data, store: true);
  }
}
