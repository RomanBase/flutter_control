part of localino;

/// Defines remote options for Localino.
class LocalinoRemoteOptions {
  /// Remote space name.
  final String space;

  /// Remote project name.
  final String project;

  /// Remote access token.
  final String access;

  /// Remote version of translations.
  final String version;

  /// Default constructor for [LocalinoRemoteOptions].
  const LocalinoRemoteOptions({
    this.space = 'public',
    required this.project,
    required this.access,
    this.version = 'latest',
  });
}

/// Setups Localino from asset file.
class LocalinoSetup {
  /// Remote space name.
  final String space;

  /// Remote project name.
  final String project;

  /// Remote access token.
  final String access;

  /// Remote version of translations.
  final String version;

  /// Asset path to localization files.
  /// Placeholder `{locale}` is used to fill locale identifier.
  final String asset;

  /// Map of supported locales and their remote timestamp.
  final Map<String, DateTime> locales;

  /// Additional options for [Localino.init].
  final Map<String, dynamic> init;

  /// Default constructor for [LocalinoSetup].
  const LocalinoSetup({
    this.space = 'public',
    required this.project,
    this.access = 'token',
    this.version = 'latest',
    this.asset = _defaultAssetsLocation,
    this.init = const {},
    this.locales = const {},
  });

  /// Returns remote options.
  LocalinoRemoteOptions get options => LocalinoRemoteOptions(
        space: space,
        project: project,
        access: access,
        version: version,
      );

  /// Returns config with parsed asset paths.
  LocalinoConfig get config => LocalinoConfig(
        defaultLocale: init['default_locale'],
        stableLocale: init['stable_locale'],
        initLocale: init['auto_init'] ?? true,
        loadDefaultLocale: init['load_default'] ?? true,
        handleSystemLocale: init['handle_system'] ?? false,
        locales: locales.map((key, value) =>
            MapEntry(key, Parse.format(asset, {'locale': key}))),
      );

  /// Loads setup from given asset file.
  /// Default path is `assets/localization/setup.json`.
  static Future<LocalinoSetup> loadAssets(
      [String path = 'assets/localization/setup.json']) async {
    final json = await rootBundle.loadString(path, cache: false);
    final data = jsonDecode(json);

    assert(data is Map, 'Invalid setup at $path:\n$json');
    assert(data.containsKey('space'),
        'Invalid setup: SPACE variable not found in $path');
    assert(data.containsKey('project'),
        'Invalid setup: PROJECT variable not found in $path');

    return LocalinoSetup(
      space: data['space'],
      project: data['project'],
      access: data['access'] ?? 'none',
      asset: data['asset'] ?? _defaultAssetsLocation,
      version: data['version'] ?? 'latest',
      locales: Parse.toMap<String, DateTime>(
        data['locales'],
        key: (key, value) => key as String,
        converter: (value) => Parse.date(value) ?? DateTime.now().toUtc(),
      ),
      init: data['init'] ?? {},
    );
  }
}

/// Map of supported locales, default locale and loading rules.
///
/// Config is passed to [Control.initControl] to init [Localino].
class LocalinoConfig {
  /// Returns current system locale.
  static String get systemLocale =>
      PlatformDispatcher.instance.locale.toString();

  /// Returns empty config with just system locale.
  static LocalinoConfig get empty => LocalinoConfig(
        locales: {
          systemLocale: null,
        },
      );

  /// Default locale key. If not provided, first locale from [locales] is used.
  final String? defaultLocale;

  /// Locale key of non-translatable data.
  final String? stableLocale;

  /// Map of locales - key: path.
  final Map<String, String?> locales;

  /// Check to init locale - [Localino.init].
  final bool initLocale;

  /// Check to load default locale.
  final bool loadDefaultLocale;

  /// Check to handle system locale.
  final bool handleSystemLocale;

  /// Returns default of first locale key.
  String get fallbackLocale =>
      defaultLocale ?? (locales.isNotEmpty ? locales.keys.first : systemLocale);

  /// [defaultLocale] - Default (not preferred) locale. This locale can contains non-translatable values (links, etc.).
  /// [locales] - Map of localization assets {'locale', 'path'}. Use [LocalinoAsset.map] for easier setup.
  /// [initLocale] - Automatically loads system or preferred locale.
  /// [loadDefaultLocale] - Loads [defaultLocale] before preferred locale.
  /// [handleSystemLocale] - Listen for default locale of the device. Whenever this locale is changed, localization will change locale (but only when there is no preferred locale).
  const LocalinoConfig({
    this.defaultLocale,
    this.stableLocale,
    required this.locales,
    this.initLocale = true,
    this.loadDefaultLocale = true,
    this.handleSystemLocale = false,
  });

  /// Converts Map of [locales] to List of [LocalinoAsset]s.
  List<LocalinoAsset> toAssets() {
    final localizationAssets = <LocalinoAsset>[];

    locales.forEach((key, value) => localizationAssets
        .add(LocalinoAsset(LocalinoAsset.normalizeLocaleKey(key), value)));

    return localizationAssets;
  }
}

/// Defines language and asset path to file with localization data.
class LocalinoAsset {
  static const empty = const LocalinoAsset('#', null);

  /// Locale key.
  /// It's preferred to use iso2 (en) or unicode (en_US) standard.
  final String locale;

  /// Asset path to file with localization data (json).
  /// - /assets/localization/en.json or /assets/localization/en_US.json
  final String? path;

  /// Returns just first 2 signs of [locale] key.
  String get iso2Locale => locale.length > 2 ? locale.substring(0, 2) : locale;

  /// Checks validity of [locale] and [path]
  bool get isValid => path != null;

  /// [locale] - It's preferred to use iso2 (en) or unicode (en_US) standard.
  /// [path] - Asset path to file with localization data (json).
  const LocalinoAsset(
    this.locale,
    this.path,
  );

  /// Parses [locale] string to [Locale].
  /// en - will be parse to [Locale('en')]
  /// en_US - will be parsed to [Locale('en', 'US')]
  /// en_US_419 - will be parsed to [Locale('en', 'US_419')]
  Locale toLocale() {
    if (locale.contains("_")) {
      final parts = locale.split("_");

      if (parts.length == 1) {
        return Locale(parts[0]);
      }

      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }

      return Locale(parts[0], locale.substring(parts[0].length));
    }

    return Locale(locale);
  }

  /// Normalize localization identifier.
  /// en -> en
  /// en-US -> en_US
  /// en-US-419 -> en_US_419
  static String normalizeLocaleKey(String locale) =>
      locale.replaceAll('-', '_');

  /// Normalize localization identifier.
  /// en -> en
  /// en_US -> en-US
  /// en_US_419 -> en-US-419
  static String normalizeLocaleTag(String locale) =>
      locale.replaceAll('_', '-');

  /// Builds a Map of {locale, path} by providing asset [path] and list of [locales].
  /// Default asset path is ./assets/localization/{locale}.json
  static Map<String, String> map(
      {String assets = _defaultAssetsLocation, required List<String> locales}) {
    final map = Map<String, String>();

    locales.forEach((locale) => map[normalizeLocaleKey(locale)] =
        Parse.format(assets, {'locale': locale}));

    return map;
  }

  /// Builds a List of [LocalinoAsset] by providing asset [path] and list of [locales].
  /// Default asset path is ./assets/localization/{locale}.json
  static List<LocalinoAsset> list(
      {String assets = _defaultAssetsLocation, required List<String> locales}) {
    final localizationAssets = <LocalinoAsset>[];

    locales.forEach((locale) => localizationAssets.add(LocalinoAsset(
        normalizeLocaleKey(locale), Parse.format(assets, {'locale': locale}))));

    return localizationAssets;
  }

  @override
  String toString() {
    return '$locale: $path';
  }
}

/// Defines result of localization change.
class LocalinoArgs {
  /// Requested locale.
  final String locale;

  /// Source of locale to load from. Asset path, runtime, network or any other.
  final String source;

  /// True if requested locale is loaded and set.
  /// Locale can be active even if not [changed].
  final bool isActive;

  /// True if locale [isActive] and is different then previous locale.
  final bool changed;

  LocalinoArgs({
    required this.locale,
    this.source = 'runtime',
    this.isActive = false,
    this.changed = false,
  });

  @override
  String toString() {
    return 'Locale $locale: from $source is active: ${isActive.toString().toUpperCase()} and locale was changed: ${changed.toString().toUpperCase()}';
  }
}
