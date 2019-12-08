import 'package:flutter_control/core.dart';

class SettingsController extends BaseController with LocalizationProvider {
  final localizationLoading = LoadingControl();

  void changeLocaleToEN() => changeLocale('en_US');

  void changeLocaleToCS() => changeLocale('cs_CZ');

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
