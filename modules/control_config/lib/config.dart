library control_config;

import 'dart:convert';
import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:control_core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'src/control_prefs.dart';
part 'src/pref_model.dart';

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
  Future init() => module!.init();

  static bool standalone() {
    if (Control.isInitialized) {
      if (Control.factory.containsKey(ControlPrefs)) {
        return false;
      }

      final module = ConfigModule();
      module.initStore(Control.factory);

      return true;
    }

    return Control.initControl(
      modules: [
        ConfigModule(),
      ],
    );
  }
}
