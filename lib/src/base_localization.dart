import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_control/core.dart';

typedef LocalizationExtractor = String Function(
    Map map, String locale, String defaultLocale);
typedef LocalizationParser = dynamic Function(dynamic data, String locale);

/// Map of supported locales, default locale and loading rules.
///
/// Config is passed to [Control.initControl] to init [BaseLocalization].
class LocalizationConfig {
  /// Default locale key. If not provided, first locale from [locales] is used.
  final String defaultLocale;

  /// Locale key of non-translatable data.
  final String stableLocale;

  /// Map of locales - key: path.
  final Map<String, String> locales;

  /// Check to init locale - [BaseLocalization.init].
  final bool initLocale;

  /// Check to load default locale.
  final bool loadDefaultLocale;

  /// Check to handle system locale.
  final bool handleSystemLocale;

  /// Returns default of first locale key.
  String get fallbackLocale =>
      defaultLocale ?? (locales.isNotEmpty ? locales.keys.first : 'en');

  /// [defaultLocale] - Default (not preferred) locale. This locale can contains non-translatable values (links, etc.).
  /// [locales] - Map of localization assets {'locale', 'path'}. Use [LocalizationAsset.map] for easier setup.
  /// [initLocale] - Automatically loads system or preferred locale.
  /// [loadDefaultLocale] - Loads [defaultLocale] before preferred locale.
  /// [handleSystemLocale] - Listen for default locale of the device. Whenever this locale is changed, localization will change locale (but only when there is no preferred locale).
  const LocalizationConfig({
    this.defaultLocale,
    this.stableLocale,
    @required this.locales,
    this.initLocale: true,
    this.loadDefaultLocale: true,
    this.handleSystemLocale: true,
  }) : assert(locales != null);

  /// Converts Map of [locales] to List of [LocalizationAsset]s.
  List<LocalizationAsset> toAssets() {
    final localizationAssets = List<LocalizationAsset>();

    locales.forEach((key, value) => localizationAssets.add(
        LocalizationAsset(LocalizationAsset.normalizeLocaleKey(key), value)));

    return localizationAssets;
  }
}

/// Defines language and asset path to file with localization data.
class LocalizationAsset {
  /// Locale key.
  /// It's preferred to use iso2 (en) or unicode (en_US) standard.
  final String locale;

  /// Asset path to file with localization data (json).
  /// - /assets/localization/en.json or /assets/localization/en_US.json
  final String assetPath;

  /// Returns just first 2 signs of [locale] key.
  String get iso2Locale => locale.length > 2 ? locale.substring(0, 2) : locale;

  /// Checks validity of [locale] and [assetPath]
  bool get isValid => locale != null && assetPath != null;

  /// [locale] - It's preferred to use iso2 (en) or unicode (en_US) standard.
  /// [assetPath] - Asset path to file with localization data (json).
  LocalizationAsset(
    this.locale,
    this.assetPath,
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

  /// Builds a Map of {locale, path} by providing asset [path] and list of [locales].
  /// Default asset path is ./assets/localization/{locale}.json
  static Map<String, String> map(
      {AssetPath path: const AssetPath(), List<String> locales}) {
    final map = Map<String, String>();

    locales.forEach((locale) =>
        map[normalizeLocaleKey(locale)] = path.localization(locale));

    return map;
  }

  /// Builds a List of [LocalizationAsset] by providing asset [path] and list of [locales].
  /// Default asset path is ./assets/localization/{locale}.json
  static List<LocalizationAsset> list(
      {AssetPath path: const AssetPath(), List<String> locales}) {
    final localizationAssets = List<LocalizationAsset>();

    locales.forEach((locale) => localizationAssets.add(LocalizationAsset(
        normalizeLocaleKey(locale), path.localization(locale))));

    return localizationAssets;
  }
}

/// Defines result of localization change.
class LocalizationArgs {
  /// Requested locale.
  final String locale;

  /// Source of locale to load from. Asset path, runtime, network or any other.
  final String source;

  /// True if requested locale is loaded and set.
  /// Locale can be active even if not [changed].
  final bool isActive;

  /// True if locale [isActive] and is different then previous locale.
  final bool changed;

  LocalizationArgs({
    this.locale,
    this.source,
    this.isActive,
    this.changed,
  });
}

/// Json/Map based localization.
class BaseLocalization extends ChangeNotifier
    with PrefsProvider
    implements Disposable {
  /// Key of shared preference where preferred locale is stored.
  static const String preference_key = 'control_locale';

  /// Default locale.
  /// This locale should be loaded first, because data can contains some shared/non translatable values (links, captions, etc.).
  final String defaultLocale;

  /// List of available localization assets.
  /// [LocalizationAsset] defines language and asset path to file with localization data.
  final List<LocalizationAsset> assets;

  /// The system-reported default locale of the device.
  Locale get deviceLocale => WidgetsBinding.instance.window.locale;

  /// The full system-reported supported locales of the device.
  List<Locale> get deviceLocales => WidgetsBinding.instance.window.locales;

  /// Returns currently loaded locale.
  String get locale => _locale;

  /// Returns currently loaded locale.
  Locale get currentLocale => getLocale(locale);

  /// Returns best possible country code based on [currentLocale] and [deviceLocale].
  String get currentCountry =>
      currentLocale?.countryCode ??
      deviceLocales
          .firstWhere((element) => locale.startsWith(element.languageCode),
              orElse: () => deviceLocale)
          .countryCode;

  /// Current locale key.
  String _locale;

  /// Current localization data.
  Map<String, dynamic> _data = Map();

  /// Enables debug mode for localization.
  /// When localization key isn't found for given locale, then [localize] returns key and current locale (key_locale).
  bool debug = true;

  /// Loading localization data is async, so check this to prevent concurrent loading.
  bool loading = false;

  /// Is [true] if any data are stored in localization map.
  bool get isActive => _data.length > 0;

  /// Is [true] if any [LocalizationAsset] is valid.
  bool get hasValidAsset =>
      assets.firstWhere((item) => item.isValid, orElse: () => null) != null;

  /// Is [true] if localization can load default locale data.
  bool get isDirty => !loading && !isActive && hasValidAsset;

  /// Custom func for [extractLocalization].
  /// Default extractor is [Map] based: {'locale': 'value'}.
  LocalizationExtractor _mapExtractor;

  /// Custom param decorator.
  /// Default decorator is [ParamDecorator.curl]: 'city' => '{city}'.
  ParamDecoratorFormat _paramDecorator = ParamDecorator.curl;

  /// Checks if this localization is main and will broadcast [LocalizationArgs] changes with [BaseLocalization] key.
  /// Only one localization should be main !
  bool main = false;

  /// Json/Map based localization.
  ///
  /// [defaultLocale] - should be loaded first, because data can contains some shared/non translatable values (links, captions, etc.).
  /// [assets] - defines locales and asset path to files with localization data.
  BaseLocalization(this.defaultLocale, this.assets);

  /// Creates new localization object based on main [Control.localization].
  factory BaseLocalization.current(List<LocalizationAsset> assets) {
    assert(Control.isInitialized);

    return BaseLocalization(Control.localization.defaultLocale, assets);
  }

  /// Subscription to default global object stream - [ControlBroadcast] with [BaseLocalization] key.
  /// Every localization change is broadcasted with result of data load.
  ///
  /// [callback] to listen results of locale changes.
  static BroadcastSubscription<LocalizationArgs> subscribeChanges(
      ValueCallback<LocalizationArgs> callback) {
    return BroadcastProvider.subscribe<LocalizationArgs>(
        BaseLocalization, callback);
  }

  /// Should be called first.
  /// Loads initial localization data - [getSystemLocale] is used to get preferred locale.
  ///
  /// [loadDefaultLocale] - loads [defaultLocale] before preferred locale.
  /// [handleSystemLocale] - listen for default locale of the device. Whenever this locale is changed, localization will change locale (but only when there is no preferred locale).
  Future<LocalizationArgs> init(
      {bool loadDefaultLocale: true,
      bool handleSystemLocale: true,
      String stableLocale}) async {
    loading = true;

    await prefs.mount();

    LocalizationArgs args;

    if (stableLocale != null) {
      args = await loadLocalizationData(stableLocale);
    }

    if (loadDefaultLocale) {
      args = await loadDefaultLocalization();
    }

    if (!isSystemLocaleActive()) {
      args = await changeToSystemLocale();
    }

    loading = false;

    if (handleSystemLocale) {
      WidgetsBinding.instance.window.onLocaleChanged = () {
        //TODO: Q: only when preferred locale is not set ??
        if (!isSystemLocaleActive()) {
          changeToSystemLocale();
        }
      };
    }

    return args;
  }

  /// Looks for best suited asset locale to device supported locale.
  ///
  /// Returns system locale or null if no locale found.
  String getAvailableAssetLocaleForDevice() {
    final locales = deviceLocales;

    if (locales != null && locales.isNotEmpty) {
      for (Locale loc in locales) {
        if (isLocalizationAvailable(loc.toString())) {
          return loc.toString();
        }
      }
    }

    return null;
  }

  /// Either device locale or locale stored in preferences.
  ///
  /// Returns preferred locale of this app instance.
  String getSystemLocale() {
    return prefs.get(preference_key) ??
        getAvailableAssetLocaleForDevice() ??
        deviceLocale?.toString();
  }

  /// Checks if preferred locale is loaded.
  ///
  /// [nullOk] Returns [true] if no [locale] is set.
  bool isSystemLocaleActive({bool nullOk: true}) {
    if (locale == null && nullOk) {
      return true;
    }

    final pref = getSystemLocale();

    return isActive && isLocaleEqual(pref, locale);
  }

  /// Removes preferred locale stored in shared preferences.
  ///
  /// [loadSystemLocale] - to load new system preferred locale.
  /// Returns result of localization change [LocalizationArgs] or just result of reset prefs [bool].
  /// Result of localization change is also broadcasted to global object stream with [BaseLocalization] key.
  Future<dynamic> resetPreferredLocale({bool loadSystemLocale: false}) async {
    prefs.set(preference_key, null);

    if (loadSystemLocale) {
      return changeToSystemLocale();
    }

    return true;
  }

  /// Changes localization to [defaultLocale].
  ///
  /// [resetPreferred] - to reset preferred locale stored in shared preferences.
  /// Returns result of localization change [LocalizationArgs].
  /// Result of localization change is also broadcast to global object stream with [BaseLocalization] key.
  Future<LocalizationArgs> loadDefaultLocalization(
      {bool resetPreferred: false}) {
    if (resetPreferred) {
      resetPreferredLocale();
    }

    return changeLocale(defaultLocale, preferred: false);
  }

  /// Changes localization to system preferred language.
  ///
  /// [getSystemLocale] is used to get preferred locale.
  /// Returns result of localization change [LocalizationArgs].
  /// Result of localization change is also broadcasted to global object stream with [BaseLocalization] key.
  Future<LocalizationArgs> changeToSystemLocale(
      {bool resetPreferred: false}) async {
    loading = true;

    final locale = getSystemLocale();

    if (locale != null) {
      if (resetPreferred) {
        resetPreferredLocale();
      }

      return await changeLocale(locale, preferred: false);
    }

    loading = false;
    return LocalizationArgs(
      locale: locale,
      isActive: false,
      changed: false,
      source: 'asset',
    );
  }

  /// Changes localization data inside this object for given [locale].
  /// Set [preferred] to store locale as system preferred into shared preferences.
  ///
  /// Returns result of localization change [LocalizationArgs].
  /// Result of localization change is also broadcasted to global object stream with [BaseLocalization] key.
  Future<LocalizationArgs> changeLocale(String locale,
      {bool preferred: true}) async {
    final args = await loadLocalizationData(locale);

    if (args.isActive) {
      _locale = locale;
      notifyListeners();

      if (preferred) {
        if (main) {
          prefs.set(preference_key, locale);
        } else {
          printDebug(
              'Only \'main\' localization can change preferred locale !!!');
        }
      }

      _broadcastArgs(args);
    }

    return args;
  }

  /// Broadcast localization changes.
  void _broadcastArgs(LocalizationArgs args) {
    if (main) {
      BroadcastProvider.broadcast(BaseLocalization, args);
    }
  }

  /// Loads localization data of [locale] key.
  /// Can be used to load non-translatable data.
  /// Returns result of localization change [LocalizationArgs].
  Future<LocalizationArgs> loadLocalizationData(String locale) async {
    loading = true;

    if (locale == null || !isLocalizationAvailable(locale)) {
      print('localization not available: $locale');
      loading = false;
      return LocalizationArgs(
        locale: locale,
        isActive: false,
        changed: false,
        source: 'asset',
      );
    }

    if (isLocaleEqual(this.locale, locale)) {
      loading = false;
      return LocalizationArgs(
        locale: locale,
        isActive: true,
        changed: false,
        source: 'asset',
      );
    }

    final args = await _loadAssetLocalization(locale, getAssetPath(locale));

    loading = false;

    return args;
  }

  /// Loads localization from asset file for given [locale] and [path].
  Future<LocalizationArgs> _loadAssetLocalization(
      String locale, String path) async {
    if (path == null) {
      return LocalizationArgs(
        locale: locale,
        isActive: false,
        changed: false,
        source: 'asset',
      );
    }

    try {
      final json = await rootBundle.loadString(path, cache: false);
      final data = jsonDecode(json);

      if (data != null) {
        data.forEach((key, value) => _data[key] = value);

        print('localization changed to: $path');

        final args = LocalizationArgs(
          locale: locale,
          isActive: true,
          changed: true,
          source: 'asset',
        );

        return args;
      }
    } catch (ex) {
      printDebug(ex.toString());
    }

    print('localization failed to change: $path');

    return LocalizationArgs(
      locale: locale,
      isActive: false,
      changed: false,
      source: 'asset',
    );
  }

  /// Returns [true] if localization file is available and is possible to load it.
  /// Do not check physical existence of file !
  bool isLocalizationAvailable(String locale) => getAssetPath(locale) != null;

  /// Checks if [a] and [b] is same or if this values points to same asset path.
  /// Comparing 'en' and 'en_US' can be true because they can point to same asset file.
  bool isLocaleEqual(String a, String b) {
    if (a == null || b == null) {
      return false;
    }

    if (a == b) {
      return true;
    }

    return getAssetPath(a) == getAssetPath(b);
  }

  /// Tries to find asset for given [locale].
  /// Locale of 'en' and 'en_US' can point to same asset file.
  ///
  /// Returns [LocalizationAsset] for given [locale] or null if localization asset is not available.
  LocalizationAsset getAsset(String locale) {
    if (locale == null) {
      return null;
    }

    for (final asset in assets) {
      if (asset.locale == locale) {
        return asset;
      }
    }

    if (locale.length < 2) {
      printDebug('Locale should have minimum of 2 chars - iso2 standard');
      return null;
    }

    final iso2Locale = locale.substring(0, 2);

    for (final asset in assets) {
      if (asset.iso2Locale == iso2Locale) {
        return asset;
      }
    }

    return null;
  }

  /// Tries to find asset path for given [locale].
  /// Locale of 'en' and 'en_US' can point to same asset file.
  ///
  /// Returns asset path for given [locale] or null if localization asset is not available.
  String getAssetPath(String locale) => getAsset(locale)?.assetPath;

  /// Tries to find [Locale] is assets for given [locale].
  /// Locale of 'en' and 'en_US' can point to same asset file, so resulted [Locale] for 'en_US' can be [Locale('en')] if only 'en.json' file exists.
  ///
  /// Returns [Locale] for given [locale] or null if localization asset is not available.
  Locale getLocale(String locale) => getAsset(locale)?.toLocale();

  /// Tries to localize text by given [key].
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String localize(String key) {
    if (_data.containsKey(key)) {
      return _data[key];
    }

    return debug ? '${key}_$_locale' : '';
  }

  /// Tries to localize text by given [key].
  ///
  /// If given [key] is not found, then tries to localize one of [alterKeys].
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String localizeOr(String key, List<String> alterKeys) {
    if (_data.containsKey(key)) {
      return _data[key];
    }

    for (final alterKey in alterKeys) {
      if (_data.containsKey(alterKey)) {
        return _data[alterKey];
      }
    }

    return debug ? '${key}_$_locale' : '';
  }

  /// Tries to localize text by given [key].
  /// Then format string with given [params].
  ///
  /// Simply replaces strings with params. For more complex formatting can be better to use [Intl].
  /// Set custom [ParamDecoratorFormat] to decorate param, for example: 'city' => '{city}' or 'city' => '$city'
  ///
  /// Default decorator is set to [ParamDecorator.curl]
  ///
  /// 'Weather in {city} is {temp}°{symbol}'
  /// Then [params] are:
  /// {
  /// {'city': 'California'},
  /// {'temp': '25.5'},
  /// {'symbol': 'C'},
  /// }
  ///
  /// Returns formatted string.
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String localizeFormat(String key, Map<String, String> params) {
    if (_data.containsKey(key)) {
      return Parse.format(_data[key], params, _paramDecorator);
    }

    return debug ? '${key}_$_locale' : '';
  }

  /// Tries to localize text by given [key] and [plural].
  ///
  /// count: {
  ///   "0": "zero",
  ///   "1": "single",
  ///   "2": "few",
  ///   "5": "many"
  ///   "other": "none of above"
  /// }
  ///
  /// plural: 1 returns 'single'
  /// plural: 4 returns 'few'
  /// plural: 9 returns 'many'
  /// plural: -1 returns 'none of above'
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String localizePlural(String key, int plural, [Map<String, String> params]) {
    if (_data.containsKey(key)) {
      if (_data[key] is Map) {
        final data = _data[key];
        final nums = List<int>();

        data.forEach(
            (num, value) => nums.add(Parse.toInteger(num, defaultValue: -1)));
        nums.sort();

        String output;

        for (final num in nums.reversed) {
          if (plural >= num) {
            output = data[num.toString()];
            break;
          }
        }

        if (output == null && data.containsKey('other')) {
          output = data['other'];
        }

        if (output != null) {
          if (params != null) {
            output = Parse.format(output, params, _paramDecorator);
          }

          return output;
        }
      }

      return _data[key];
    }

    return debug ? '$key[$plural]_$_locale' : '';
  }

  /// Tries to localize text by given [key] and [gender].
  ///
  /// child: {
  ///   "male": "boy",
  ///   "female": "girl",
  ///   "other": "child"
  /// }
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String localizeGender(String key, String gender) {
    if (_data.containsKey(key)) {
      if (_data[key] is Map) {
        switch (gender) {
          case 'male':
            return _data[key]['male'] ?? _data[key]['other'];
          case 'female':
            return _data[key]['female'] ?? _data[key]['other'];
          default:
            return _data[key]['other'];
        }
      }

      return _data[key];
    }

    return debug ? '$key[$gender]_$_locale' : '';
  }

  /// Tries to localize text by given [key].
  ///
  /// days: [
  ///   "monday", "tuesday", "wednesday"
  /// ]
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  List<String> localizeList(String key) {
    if (_data.containsKey(key)) {
      final data = _data[key];

      if (data is List) {
        return data.cast<String>();
      }

      if (data is Map) {
        return data.values.cast<String>();
      }

      return [_data[key]];
    }

    return debug ? ['${key}_$_locale'] : [];
  }

  /// Tries to localize text by given [key].
  ///
  /// {
  ///   "address": {
  ///     "name": "Maria De Flutter",
  ///     "street": "St. Maria 1189",
  ///     "city": "St. Flutter"
  ///   }
  /// }
  ///
  /// [key] 'address' returns [Map] of json data if parser is not provided.
  /// [parser] custom parser of returned data - can return custom Address class.
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  dynamic localizeDynamic(String key,
      {LocalizationParser parser, dynamic defaultValue}) {
    if (_data.containsKey(key)) {
      if (parser != null) {
        return parser(_data[key], locale);
      }

      return _data[key];
    }

    return defaultValue ?? (debug ? '${key}_$_locale' : '');
  }

  /// Tries to localize text by given locale.
  /// Set [setCustomExtractor] to provide custom parsing.
  ///
  /// Default extractor works only with locale map {'locale' : 'value'}
  /// [locale] - default is current locale.
  /// [defaultLocale] - default is locale passed into constructor.
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String extractLocalization(dynamic data,
      {String locale, String defaultLocale}) {
    locale ??= this.locale;
    defaultLocale ??= this.defaultLocale;

    if (_mapExtractor != null) {
      return _mapExtractor(data, locale, defaultLocale);
    }

    if (data is Map) {
      if (data.containsKey(locale)) {
        return data[locale];
      }

      if (data.containsKey(defaultLocale)) {
        return data[defaultLocale];
      }
    }

    return debug ? 'empty_{$locale} at ${data?.toString()}' : '';
  }

  /// Sets custom extractor for [extractLocalization].
  ///
  /// Default extractor is [Map] based: {'locale': 'value'}.
  void setCustomExtractor(LocalizationExtractor extractor) =>
      _mapExtractor = extractor;

  /// Sets custom decorator for string formatting
  ///
  /// Default decorator is [ParamDecorator.curl]: 'city' => '{city}'.
  void setCustomParamDecorator(ParamDecoratorFormat decorator) =>
      _paramDecorator = decorator;

  /// Updates value in current localization set.
  /// This update is only runtime and isn't stored to localization file.
  void set(String key, dynamic value) => _data[key] = value;

  /// Updates data in current localization set.
  /// This update is only runtime and isn't stored to localization file.
  void setData(Map<String, dynamic> data) async {
    data.forEach((key, value) => _data[key] = value);
  }

  /// Checks if given [key] can be localized.
  bool contains(String key) => _data.containsKey(key);

  /// Checks if one of given [keys] can be localized.
  bool containsOneOf(List<String> keys) {
    for (var key in keys) {
      if (_data.containsKey(key)) {
        return true;
      }
    }

    return false;
  }

  /// Clears loaded data.
  void clear() {
    _locale = null;
    _data.clear();
  }

  /// Delegate of [BaseLocalization] to use this localization as [LocalizationsDelegate].
  ///
  /// Use [LocalizationProvider.of(context)] to find delegate in current widget scope.
  BaseLocalizationDelegate get delegate => BaseLocalizationDelegate(this);

  @override
  void dispose() {
    super.dispose();

    clear();
  }
}

/// Delegate of [BaseLocalization] to use with [LocalizationsDelegate].
///
/// Use [LocalizationProvider.of(context)] to find delegate in the widget tree that corresponds to the given [context].
class BaseLocalizationDelegate extends LocalizationsDelegate<BaseLocalization> {
  /// Localization to work with.
  final BaseLocalization localization;

  /// Creates delegate of [BaseLocalization].
  ///
  /// Typically this constructor is not called directly, but instance of delegate is created with [BaseLocalization.delegate].
  BaseLocalizationDelegate(this.localization);

  /// Active locale of [BaseLocalization].
  ///
  /// Returns [BaseLocalization.getLocale].
  Locale get locale => localization.getLocale(localization.locale);

  @override
  bool isSupported(Locale locale) =>
      localization.isLocalizationAvailable(locale.toString());

  @override
  Future<BaseLocalization> load(Locale locale) async {
    await localization.changeLocale(locale.toString());

    return localization;
  }

  @override
  bool shouldReload(LocalizationsDelegate old) => false;

  List<Locale> supportedLocales() {
    final list = List<Locale>();

    localization.assets.forEach((asset) {
      list.add(asset.toLocale());
    });

    return list;
  }
}

/// Mixin class to provide [BaseLocalization] - localize functions.
///
/// Access to [BaseLocalizationDelegate] is handled via static functions.
mixin LocalizationProvider {
  /// Shortcut for delegate of default [BaseLocalization].
  static BaseLocalizationDelegate get delegate => Control.localization.delegate;

  /// Delegate of [BaseLocalization] for the widget tree that corresponds to the given [context].
  ///
  /// Note: usable only with [LocalizationsDelegate]. If delegate is not specified use [Control.localization] instead.
  static BaseLocalization of(BuildContext context) {
    return Localizations.of<BaseLocalization>(context, BaseLocalization);
  }

  ///Instance of default [BaseLocalization]
  @protected
  BaseLocalization get localization => Control.localization;

  ///[BaseLocalization.localize]
  @protected
  String localize(String key) => localization.localize(key);

  ///[BaseLocalization.localizeOr]
  @protected
  String localizeOr(String key, List<String> alterKeys) =>
      localization.localizeOr(key, alterKeys);

  ///[BaseLocalization.localizeFormat]
  @protected
  String localizeFormat(String key, Map<String, String> params) =>
      localization.localizeFormat(key, params);

  ///[BaseLocalization.localizePlural]
  @protected
  String localizePlural(String key, int plural, [Map<String, String> params]) =>
      localization.localizePlural(key, plural, params);

  ///[BaseLocalization.localizeGender]
  @protected
  String localizeGender(String key, String gender) =>
      localization.localizeGender(key, gender);

  ///[BaseLocalization.localizeList]
  @protected
  List<String> localizeList(String key) => localization.localizeList(key);

  ///[BaseLocalization.localizeDynamic]
  @protected
  dynamic localizeDynamic(String key,
          {LocalizationParser parser, dynamic defaultValue}) =>
      localization.localizeDynamic(key,
          parser: parser, defaultValue: defaultValue);

  ///[BaseLocalization.extractLocalization]
  @protected
  String extractLocalization(dynamic data,
          {String locale, String defaultLocale}) =>
      localization.extractLocalization(data,
          locale: locale, defaultLocale: defaultLocale);
}
