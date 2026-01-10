library control_config;

import 'dart:convert';

import 'package:control_core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'src/control_prefs.dart';
part 'src/pref_model.dart';

/// A [ControlModule] that integrates `control_config` with the `ControlFactory`.
///
/// This module ensures that [ControlPrefs] is initialized and available through
/// the [ControlFactory] during the application's startup.
///
/// By registering `ConfigModule`, [SharedPreferences] becomes accessible
/// globally via [PrefsProvider.instance] or `Control.get<ControlPrefs>()`.
class ConfigModule extends ControlModule<ControlPrefs> {
  /// Sets a high priority to ensure `ControlPrefs` is initialized early.
  @override
  int get priority => 100;

  /// Initializes the module by either retrieving an existing [ControlPrefs]
  /// instance from the [ControlFactory] or creating a new one if not present.
  @override
  void initModule() {
    super.initModule();

    if (!isInitialized) {
      module = ControlPrefs();
    }
  }

  /// Asynchronously mounts (initializes) [SharedPreferences].
  @override
  Future init() => module!.init();

  /// Initializes `control_config` as a standalone module if `ControlFactory` is not yet initialized.
  ///
  /// This is a convenience method for quickly setting up preferences without needing
  /// to manually call `Control.initControl` with `ConfigModule`.
  ///
  /// Returns `true` if initialization was successful, `false` otherwise.
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
