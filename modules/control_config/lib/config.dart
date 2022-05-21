library control_config;

import 'dart:convert';

import 'package:flutter_control/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'src/control_prefs.dart';

class ConfigModule extends ControlModule<ControlPrefs> {
  int get priority => 100;

  ConfigModule() {
    initModule();
  }

  void initModule() {
    super.initModule();

    if (!isInitialized) {
      module = ControlPrefs();
    }
  }

  @override
  Future? init() => module!.init();

  static bool initControl() {
    if (Control.isInitialized) {
      if (Control.factory.containsKey(Localino)) {
        return false;
      }

      final module = ConfigModule();
      module.initStore();

      return true;
    }

    return Control.initControl(
      modules: [
        ConfigModule(),
      ],
    );
  }
}
