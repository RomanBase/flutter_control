/// Support for doing something awesome.
///
/// More dartdocs go here.
library localino;

import 'dart:async';
import 'dart:convert';

import 'package:control_config/config.dart';
import 'package:control_core/core.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

part 'src/config.dart';

part 'src/delegate.dart';

part 'src/localization.dart';

part 'src/provider.dart';

typedef LocalizationExtractor = String Function(
    Map map, String locale, String defaultLocale);
typedef LocalizationParser = dynamic Function(dynamic data, String? locale);

class LocalinoModule extends ControlModule<Localino> {
  final LocalinoConfig config;

  @override
  Map<Type, Initializer> get subModules => {
        ConfigModule: (_) => ConfigModule(),
      };

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
  Future? init() => config.initLocale
      ? module!.init(
          loadDefaultLocale: config.loadDefaultLocale,
          handleSystemLocale: config.handleSystemLocale,
          stableLocale: config.stableLocale,
        )
      : null;

  static Future<bool> initWithControl(LocalinoConfig config,
      {Map? args, bool? debug}) async {
    if (Control.isInitialized) {
      if (Control.factory.containsKey(Localino)) {
        return false;
      }

      final module = LocalinoModule(config, debug: debug);
      module.initStore(includeSubModules: true);

      await module.initWithSubModules(args: args);

      return true;
    }

    return ControlModule.initControl(
      LocalinoModule(config, debug: debug),
      args: args,
      debug: debug,
    );
  }
}
