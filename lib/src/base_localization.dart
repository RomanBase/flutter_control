import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_control/core.dart';

typedef LocalizationExtractor = String Function(Map map, String locale, String defaultLocale);
typedef LocalizationParser = dynamic Function(dynamic data, String locale);

/// Defines language and asset path to file with localization data.
class LocalizationAsset {
  /// Locale key.
  /// Use iso2 (en) or unicode (en_US) standard.
  final String locale;

  /// Asset path to file with localization data (json).
  /// - /assets/localization/en.json or /assets/localization/en_US.json
  final String assetPath;

  String get iso2Locale => locale.substring(0, 2);

  bool get isValid => locale != null && assetPath != null;

  /// Default constructor
  LocalizationAsset(
    this.locale,
    this.assetPath,
  );

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
}

/// Defines result of localization change.
class LocalizationArgs {
  final String locale;
  final String source;
  final bool isActive;
  final bool changed;

  LocalizationArgs({
    this.locale,
    this.source,
    this.isActive,
    this.changed,
  });
}

/// Simple [Map] based localization.
/// - /assets/localization/en.json
class BaseLocalization with PrefsProvider {
  /// key to shared preferences where preferred locale is stored.
  static const String preference_key = 'pref_locale';

  /// default app locale.
  final String defaultLocale;

  /// List of available localization assets.
  /// LocalizationAssets defines language and asset path to file with localization data.
  final List<LocalizationAsset> assets;

  /// Returns current Locale of device.
  Locale get deviceLocale => WidgetsBinding.instance.window.locale;

  /// returns currently loaded locale.
  String get locale => _locale;

  /// Current locale.
  String _locale;

  /// Current localization data.
  Map<String, dynamic> _data = Map();

  /// Enables debug mode for localization.
  /// When localization key isn't found for given locale, then [localize] returns key and current locale (key_locale).
  bool debug = true;

  /// TODO: prevent concurrent loading
  bool loading = false;

  /// Checks if any data are stored in localization.
  bool get isActive => _data.length > 0;

  bool get hasValidAsset => assets.firstWhere((item) => item.isValid, orElse: () => null) != null;

  bool get isDirty => !loading && !isActive && hasValidAsset;

  /// Custom func for [extractLocalization].
  LocalizationExtractor _mapExtractor;

  /// Default constructor
  BaseLocalization(this.defaultLocale, this.assets);

  LocalizationArgs asArgs() => LocalizationArgs(
        locale: locale,
        isActive: isActive,
        changed: false,
        source: 'runtime',
      );

  Future<LocalizationArgs> init({bool loadDefaultLocale: true}) async {
    loading = true;

    await prefs.mount();

    LocalizationArgs args;

    if (loadDefaultLocale) {
      args = await loadDefaultLocalization();
    }

    if (!isSystemLocaleActive()) {
      args = await changeToSystemLocale();
    }

    loading = false;

    WidgetsBinding.instance.window.onLocaleChanged = () {
      if (!isSystemLocaleActive()) {
        changeToSystemLocale();
      }
    };

    return args;
  }

  static BroadcastSubscription<LocalizationArgs> subscribeChanges(ValueCallback<LocalizationArgs> callback) {
    return BroadcastProvider.subscribe<LocalizationArgs>(BaseLocalization, callback);
  }

  String getAvailableAssetLocaleForDevice() {
    final locales = WidgetsBinding.instance.window.locales;

    if (locales.length > 0) {
      for (Locale loc in locales) {
        if (isLocalizationAvailable(loc.toString())) {
          return loc.toString();
        }
      }
    }

    return null;
  }

  /// Returns preferred locale of this app instance.
  /// Either Device locale or locale stored in preferences.
  String getSystemLocale() {
    return prefs.get(preference_key) ?? getAvailableAssetLocaleForDevice() ?? deviceLocale?.toString();
  }

  /// Checks if preferred locale is loaded.
  bool isSystemLocaleActive({bool nullOk: true}) {
    if (locale == null && nullOk) {
      return true;
    }

    final pref = getSystemLocale();

    return isActive && isLocaleEqual(pref, locale);
  }

  void resetPreferredLocale() => prefs.set(preference_key, null);

  /// Changes localization to [defaultLocale].
  Future<LocalizationArgs> loadDefaultLocalization() => changeLocale(defaultLocale, preferred: false);

  /// Changes localization to system language
  /// Set [preferred] - true: changes localization to in app preferred language (if previously set).
  Future<LocalizationArgs> changeToSystemLocale() async {
    loading = true;

    final locale = getSystemLocale();

    if (locale != null) {
      return await changeLocale(locale);
    }

    loading = false;
    return LocalizationArgs(
      locale: locale,
      isActive: false,
      changed: false,
      source: 'asset',
    );
  }

  /// Returns true if localization file is available and is possible to load it.
  bool isLocalizationAvailable(String locale) => getAssetPath(locale) != null;

  /// Checks if [a] and [b] is same or if this locales points to same asset path.
  /// Comparing 'en' and 'en_US' can be true because they can point to same asset.
  bool isLocaleEqual(String a, String b) {
    if (a == null || b == null) {
      return false;
    }

    if (a == b) {
      return true;
    }

    return getAssetPath(a) == getAssetPath(b);
  }

  /// Returns asset path for given locale or null if localization asset is not available.
  String getAssetPath(String locale) {
    for (final asset in assets) {
      if (asset.locale == locale) {
        return asset.assetPath;
      }
    }

    if (locale.length < 2) {
      printDebug('Locale should have minimum of 2 chars - iso2 standard');
      return null;
    }

    final iso2Locale = locale.substring(0, 2);

    for (final asset in assets) {
      if (asset.iso2Locale == iso2Locale) {
        return asset.assetPath;
      }
    }

    return null;
  }

  /// Changes manually localization data, but only for current app session.
  Future<LocalizationArgs> changeLocaleData(Map<String, dynamic> data, {String locale}) async {
    data.forEach((key, value) => _data[key] = value);

    if (locale != null) {
      _locale = locale;
    }

    final args = LocalizationArgs(
      locale: _locale,
      isActive: true,
      changed: true,
      source: 'runtime',
    );

    BroadcastProvider.broadcast(BaseLocalization, args);

    return args;
  }

  /// Changes localization data inside this object.
  /// If localization isn't available, default localization is then used.
  /// It can take a while because localization is loaded from json file.
  Future<LocalizationArgs> changeLocale(String locale, {bool preferred: true}) async {
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

    if (args.isActive) {
      _locale = locale;
      if (preferred) {
        prefs.set(preference_key, locale);
      }

      BroadcastProvider.broadcast(BaseLocalization, args);
    }

    return args;
  }

  /// Loads localization from asset file for given locale.
  Future<LocalizationArgs> _loadAssetLocalization(String locale, String path) async {
    if (path == null) {
      return LocalizationArgs(
        locale: locale,
        isActive: false,
        changed: false,
        source: 'asset',
      );
    }

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

    print('localization failed to change: $path');

    return LocalizationArgs(
      locale: locale,
      isActive: false,
      changed: false,
      source: 'asset',
    );
  }

  /// Tries to localize text by given [key].
  /// Enable/Disable debug mode to show/hide missing localizations.
  String localize(String key) {
    if (_data.containsKey(key)) {
      return _data[key];
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
  String localizePlural(String key, int plural) {
    if (_data.containsKey(key)) {
      if (_data[key] is Map) {
        final data = _data[key];
        final nums = List<int>();

        data.forEach((num, value) => nums.add(Parse.toInteger(num, defaultValue: -1)));
        nums.sort();

        for (final num in nums.reversed) {
          if (plural >= num) {
            return data[num.toString()];
          }
        }

        if (data.contains['other']) {
          return data['other'];
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
      if (_data[key] is List) {
        return _data[key].cast<String>();
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
  dynamic localizeDynamic(String key, {LocalizationParser parser, dynamic defaultValue}) {
    if (_data.containsKey(key)) {
      if (parser != null) {
        return parser(_data[key], locale);
      }

      return _data[key];
    }

    return defaultValue ?? (debug ? '${key}_$_locale' : '');
  }

  /// Tries to localize text by given locale.
  /// Set [BaseLocalization.setCustomExtractor] to provide custom parsing.
  ///
  /// Default extractor works only with locale map {'locale' : 'value'}
  /// [locale] - default is current locale.
  /// [defaultLocale] - default is locale passed into constructor.
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String extractLocalization(dynamic data, {String locale, String defaultLocale}) {
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

  ///This extractor will be used in [BaseLocalization.extractLocalization] function.
  void setCustomExtractor(LocalizationExtractor extractor) => _mapExtractor = extractor;

  /// Updates value in current set.
  /// This update is only runtime and isn't stored to localization file.
  void update(String key, dynamic value) => _data[key] = value;

  BaseLocalizationDelegate asDelegate() => BaseLocalizationDelegate(this);
}

class LocalizationProvider {
  ///Instance of [BaseLocalization]
  @protected
  BaseLocalization get localization => Control.localization();

  ///[BaseLocalization.localize]
  @protected
  String localize(String key) => localization.localize(key);

  ///[BaseLocalization.localizePlural]
  @protected
  String localizePlural(String key, int plural) => localization.localizePlural(key, plural);

  ///[BaseLocalization.localizeGender]
  @protected
  String localizeGender(String key, String gender) => localization.localizeGender(key, gender);

  ///[BaseLocalization.localizeList]
  @protected
  List<String> localizeList(String key) => localization.localizeList(key);

  ///[BaseLocalization.localizeDynamic]
  @protected
  dynamic localizeDynamic(String key, {LocalizationParser parser, dynamic defaultValue}) => localization.localizeDynamic(key, parser: parser, defaultValue: defaultValue);

  ///[BaseLocalization.extractLocalization]
  @protected
  String extractLocalization(dynamic data, {String locale, String defaultLocale}) => localization.extractLocalization(data, locale: locale, defaultLocale: defaultLocale);
}

class BaseLocalizationDelegate extends LocalizationsDelegate<BaseLocalization> {
  final BaseLocalization localization;

  BaseLocalizationDelegate(this.localization);

  @override
  bool isSupported(Locale locale) => localization.isLocalizationAvailable(locale.toString());

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
