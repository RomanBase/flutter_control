/// A comprehensive localization solution for Flutter applications.
///
/// This library provides tools for managing translations, handling different locales,
/// and optionally synchronizing localization data with a remote source.
library localino;

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:control_config/config.dart';
import 'package:control_core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

part 'src/config.dart';

part 'src/delegate.dart';

part 'src/localization.dart';

part 'src/provider.dart';

part 'src/remote.dart';

const _defaultAssetsLocation = 'assets/localization/{locale}.json';

/// A function that extracts a localized string from a given map.
///
/// [map] is the source map containing localization data.
/// [locale] is the target locale for extraction.
/// [defaultLocale] is the fallback locale if the target locale is not found.
typedef LocalizationExtractor = String Function(
    Map map, String locale, String defaultLocale);

/// A function that parses raw localization data into a desired type.
///
/// [data] is the raw localization data.
/// [locale] is the current locale.
typedef LocalizationParser = dynamic Function(dynamic data, String? locale);

/// Options for initializing the [LocalinoModule].
class LocalinoOptions {
  /// Path to the localization setup JSON file.
  final String path;

  /// Optional [LocalinoConfig] to use instead of loading from `path`.
  final LocalinoConfig? config;

  /// Factory for creating [LocalinoRemoteApi] instance.
  final InitFactory<LocalinoRemoteApi>? remote;

  /// Whether to enable remote synchronization.
  final bool remoteSync;

  /// Optional [LocalinoSetup] instance.
  LocalinoSetup? setup;

  /// Creates a new [LocalinoOptions] instance.
  LocalinoOptions({
    this.path = 'assets/localization/setup.json',
    this.config,
    this.setup,
    this.remote,
    this.remoteSync = false,
  });

  /// Converts the options into a [LocalinoConfig] by loading the setup if necessary.
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

/// A [ControlModule] for integrating [Localino] into an application.
class LocalinoModule extends ControlModule<Localino> {
  /// The options for configuring the [Localino] instance.
  final LocalinoOptions options;

  @override
  Map<Type, InitFactory> get subModules => {
        ConfigModule: (_) => ConfigModule(),
      };

  @override
  Map get entries => {
        ...super.entries,
        LocalinoRemote: LocalinoRemote(),
      };

  @override
  Map<Type, InitFactory> get factories => {
        if (options.remote != null)
          LocalinoRemoteApi: (args) => options.remote!.call(args),
      };

  /// Creates a [LocalinoModule] with the given [options].
  ///
  /// [debug] A flag to enable debug mode for localization.
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
  Future init() async {
    final config = await options.toConfig();
    final localino = module!;
    final remote = Control.get<LocalinoRemote>()!;

    remote.options = options.setup?.options;

    localino._setup(
      config.fallbackLocale,
      config.toAssets(),
      (locale) => remote.getLocalTranslations(locale: locale),
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

  /// Initializes [Localino] as a standalone module.
  ///
  /// This method is useful for applications that don't use the full [Control] framework,
  /// or for testing purposes.
  ///
  /// Returns `true` if [Localino] was initialized successfully, `false` otherwise.
  static Future<bool> standalone(LocalinoOptions options,
      {Map? args, bool? debug}) async {
    if (Control.isInitialized) {
      if (Control.factory.containsKey(Localino)) {
        printDebug('Localino (main) can be initialized only once.');
        return false;
      }

      final module = LocalinoModule(options, debug: debug);
      module.initStore(Control.factory, includeSubModules: true);

      await module.initWithSubModules(Control.factory, args: args);

      return true;
    }

    return ControlModule.initControl(
      LocalinoModule(options, debug: debug),
      args: args,
      debug: debug,
    );
  }
}
