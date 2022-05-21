/// Support for doing something awesome.
///
/// More dartdocs go here.
library localino;

import 'dart:async';
import 'dart:convert';

import 'package:control_config/config.dart';
import 'package:control_core/core.dart';
import 'package:flutter/services.dart' show rootBundle;

part 'src/config.dart';

part 'src/delegate.dart';

part 'src/localization.dart';

part 'src/provider.dart';

typedef LocalizationExtractor = String Function(Map map, String locale, String defaultLocale);
typedef LocalizationParser = dynamic Function(dynamic data, String? locale);

class LocalinoModule extends ControlModule<Localino> {
  final LocalinoConfig config;

  LocalinoModule(this.config, {bool? debug}) {
    initModule();
    module!.debug = debug ?? Control.debug;
  }

  @override
  void initModule() {
    super.initModule();

    if (!isInitialized) {
      module = Localino(config.fallbackLocale, config.toAssets());
      module!.main = true;
    }
  }

  @override
  Future<void> init() => module!.init(
        loadDefaultLocale: config.loadDefaultLocale,
        handleSystemLocale: config.handleSystemLocale,
        stableLocale: config.stableLocale,
      );

  static bool initControl(LocalinoConfig config, {bool? debug}) {
    if (Control.isInitialized) {
      if (Control.factory.containsKey(Localino)) {
        return false;
      }

      final module = LocalinoModule(config, debug: debug);
      module.initStore();

      return true;
    }

    return Control.initControl(
      modules: [
        PrefsModule(),
        LocalinoModule(config, debug: debug),
      ],
    );
  }
}
