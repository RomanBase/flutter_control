/// Support for doing something awesome.
///
/// More dartdocs go here.
library localino;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_control/core.dart';

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

      module.entries.forEach((key, value) {
        Control.set(key: key, value: value);
      });

      return true;
    }

    return Control.initControl(
      modules: [
        LocalinoModule(config, debug: debug),
      ],
    );
  }
}
