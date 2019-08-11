import 'package:flutter_control/core.dart';

class SettingsController extends BaseController with LocalizationProvider {
  final localizationLoading = LoadingControl();

  void changeLocaleToEN() => changeLocale('en');

  void changeLocaleToCS() => changeLocale('cs');

  Future<void> changeLocale(String locale) async {
    localizationLoading.progress();

    await localization.changeLocale(locale).then((args) {
      if (args.changed) {
        control.notifyAppState();
      }
    });

    localizationLoading.done();
  }
}
