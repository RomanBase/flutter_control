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

part 'src/remote.dart';

const _defaultAssetsLocation = 'assets/localization/{locale}.json';

typedef LocalizationExtractor = String Function(
    Map map, String locale, String defaultLocale);
typedef LocalizationParser = dynamic Function(dynamic data, String? locale);

class LocalinoOptions {
  final String path;
  final LocalinoConfig? config;
  final Initializer<LocalinoRemoteApi>? remote;
  final bool remoteSync;

  LocalinoSetup? setup;

  LocalinoOptions({
    this.path = 'assets/localization/setup.json',
    this.config,
    this.setup,
    this.remote,
    this.remoteSync = false,
  });

  Future<LocalinoConfig> toConfig() async {
    if (config != null) {
      printDebug('Initializing Localino from Config');
      return config!;
    }

    if (setup == null) {
      printDebug('Initializing Localino from Assets Setup');
      await LocalinoSetup.loadAssets(path).then((value) {
        setup = value;
      }).catchError((err) {
        printDebug(err);
      });
    } else {
      printDebug('Initializing Localino from Setup');
    }

    return setup?.config ?? LocalinoConfig.empty;
  }
}

class LocalinoModule extends ControlModule<Localino> {
  final LocalinoOptions options;

  @override
  Map<Type, Initializer> get subModules => {
        ConfigModule: (_) => ConfigModule(),
      };

  @override
  Map get entries => {
        ...super.entries,
        LocalinoRemote: LocalinoRemote(),
      };

  @override
  Map<Type, Initializer> get initializers => {
        if (options.remote != null)
          LocalinoRemoteApi: (args) => options.remote!.call(args),
      };

  LocalinoModule(this.options, {bool? debug}) {
    initModule();
    module!.debug = debug ?? Control.debug;
  }

  @override
  void initModule() {
    super.initModule();

    if (!isInitialized) {
      module = Localino._()..main = true;
    }
  }

  @override
  Future? init() async {
    final config = await options.toConfig();
    final localino = module!;
    final remote = Control.get<LocalinoRemote>()!;

    remote.options = options.setup?.options;

    localino._setup(
      config.fallbackLocale,
      config.toAssets(),
      () => remote.getLocalTranslations(),
    );

    remote.initialize(
      locales: options.setup?.locales,
      remoteSync: options.remoteSync,
      initialFetch: false,
    );

    return config.initLocale
        ? localino.init(
            loadDefaultLocale: config.loadDefaultLocale,
            handleSystemLocale: config.handleSystemLocale,
            stableLocale: config.stableLocale,
          )
        : null;
  }

  static Future<bool> standalone(LocalinoOptions options,
      {Map? args, bool? debug}) async {
    if (Control.isInitialized) {
      if (Control.factory.containsKey(Localino)) {
        printDebug('Localino (main) can be initialized only once.');
        return false;
      }

      final module = LocalinoModule(options, debug: debug);
      module.initStore(includeSubModules: true);

      await module.initWithSubModules(args: args);

      return true;
    }

    return ControlModule.initControl(
      LocalinoModule(options, debug: debug),
      args: args,
      debug: debug,
    );
  }
}
