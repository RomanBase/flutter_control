import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_control/core.dart';

typedef LocalizationExtractor = String Function(Map map, String locale, String defaultLocale);
typedef LocalizationParser = dynamic Function(dynamic data, String locale);

/// Defines language and asset path to file with localization data.
class LocalizationAsset {
  /// Locale key in iso2 standard (en, es, etc.).
  final String iso2Locale;

  /// Asset path to file with localization data (json).
  /// - /assets/localization/en.json
  final String assetPath;

  /// Default constructor
  LocalizationAsset(
    this.iso2Locale,
    this.assetPath,
  );
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

  /// default app locale in iso2 standard.
  final String defaultLocale;

  /// List of available localization assets.
  /// LocalizationAssets defines language and asset path to file with localization data.
  final List<LocalizationAsset> assets;

  /// returns locale in iso2 standard (en, es, etc.).
  String get locale => _locale;

  /// Current locale in iso2 standard (en, es, etc.).
  String _locale;

  /// Current localization data.
  Map<String, dynamic> _data = Map();

  /// Enables debug mode for localization.
  /// When localization key isn't found for given locale, then [localize] returns key and current locale (key_locale).
  bool debug = true;

  /// Checks if any data are stored in localization.
  bool get isActive => _data.length > 0;

  /// Custom func for [extractLocalization].
  LocalizationExtractor _mapExtractor;

  /// Default constructor
  BaseLocalization(this.defaultLocale, this.assets);

  /// Returns current Locale of device.
  Locale deviceLocale(BuildContext context) {
    return Localizations.localeOf(context, nullOk: true);
  }

  /// Changes localization to [defaultLocale].
  Future<LocalizationArgs> loadDefaultLocalization() => changeLocale(defaultLocale);

  /// Changes localization to system language
  /// Set [preferred] - true: changes localization to in app preferred language (if previously set).
  Future<LocalizationArgs> changeToSystemLocale(BuildContext context, {bool preferred: true}) async {
    final pref = preferred ? await prefs.get(preference_key) : null;

    String locale;

    if (pref != null && isLocalizationAvailable(pref)) {
      locale = pref;
    } else {
      locale = deviceLocale(context)?.languageCode;
    }

    if (locale != null) {
      return await changeLocale(locale);
    }

    return LocalizationArgs(
      locale: locale,
      isActive: false,
      changed: false,
      source: 'asset',
    );
  }

  /// Returns true if localization file is available and is possible to load it.
  bool isLocalizationAvailable(String iso2Locale) {
    for (final asset in assets) {
      if (asset.iso2Locale == iso2Locale) {
        return true;
      }
    }

    return false;
  }

  /// Returns asset path for given locale or null if localization asset is not available.
  String getAssetPath(String iso2Locale) {
    for (final asset in assets) {
      if (asset.iso2Locale == iso2Locale) {
        return asset.assetPath;
      }
    }

    return null;
  }

  /// Changes manually localization data, but only for current app session.
  Future<LocalizationArgs> changeRawLocale(Map<String, dynamic> data) async {
    data.forEach((key, value) => _data[key] = value);

    final args = LocalizationArgs(
      locale: locale,
      isActive: true,
      changed: true,
      source: 'runtime',
    );

    BroadcastProvider.broadcast(ControlKey.localization, args);

    return args;
  }

  /// Changes localization data inside this object.
  /// If localization isn't available, default localization is then used.
  /// It can take a while because localization is loaded from json file.
  Future<LocalizationArgs> changeLocale(String iso2Locale, {bool preferred: true}) async {
    if (iso2Locale == null || !isLocalizationAvailable(iso2Locale)) {
      print('localization not available: $iso2Locale');
      return LocalizationArgs(
        locale: iso2Locale,
        isActive: false,
        changed: false,
        source: 'asset',
      );
    }

    if (preferred) {
      prefs.set(preference_key, iso2Locale);
    }

    if (_locale == iso2Locale) {
      return LocalizationArgs(
        locale: locale,
        isActive: true,
        changed: false,
        source: 'asset',
      );
    }

    _locale = iso2Locale;
    return await _initLocalization(iso2Locale, getAssetPath(iso2Locale));
  }

  /// Loads localization from asset file for given locale.
  Future<LocalizationArgs> _initLocalization(String locale, String path) async {
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

      BroadcastProvider.broadcast(ControlKey.localization, args);

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
  /// json: {
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
    if (_data.containsKey(key) && _data[key] is Map) {
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

    return debug ? '$key[$plural]_$_locale' : '';
  }

  /// Tries to localize text by given [key].
  ///
  /// json: [
  ///   "monday", "tuesday", "wednesday", etc..
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
  /// [key] 'address' returns [Map] of json data.
  /// [parser] custom parser of returned data.
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  dynamic localizeDynamic(String key, {LocalizationParser parser}) {
    if (_data.containsKey(key)) {
      if (parser != null) {
        return parser(_data[key], locale);
      }

      return _data[key];
    }

    return debug ? '${key}_$_locale' : '';
  }

  /// Tries to localize text by given key.
  /// Enable/Disable debug mode to show/hide missing localizations.
  /// [BaseLocalization.setCustomExtractor] to provide custom parsing.
  /// Default extractor works only with locale map {'locale' : 'value'}
  String extractLocalization(dynamic data, {String iso2Locale, String defaultLocale}) {
    iso2Locale ??= this.locale;
    defaultLocale ??= this.defaultLocale;

    if (_mapExtractor != null) {
      return _mapExtractor(data, iso2Locale, defaultLocale);
    }

    if (data is Map) {
      if (data.containsKey(iso2Locale)) {
        return data[iso2Locale];
      }

      if (data.containsKey(defaultLocale)) {
        return data[defaultLocale];
      }
    }

    return debug ? 'empty_{$iso2Locale}_$defaultLocale' : '';
  }

  ///This extractor will be used in [BaseLocalization.extractLocalization] function.
  void setCustomExtractor(LocalizationExtractor extractor) => _mapExtractor = extractor;

  /// Updates value in current set.
  /// This update is only runtime and isn't stored to localization file.
  void update(String key, dynamic value) => _data[key] = value;
}

class LocalizationProvider {
  ///Instance of [BaseLocalization]
  @protected
  BaseLocalization get localization => ControlProvider.of(ControlKey.localization);

  ///[BaseLocalization.localize]
  @protected
  String localize(String key) => localization.localize(key);

  ///[BaseLocalization.localizePlural]
  @protected
  String localizePlural(String key, int plural) => localization.localizePlural(key, plural);

  ///[BaseLocalization.localizeList]
  @protected
  List<String> localizeList(String key) => localization.localizeList(key);

  ///[BaseLocalization.localizeDynamic]
  @protected
  dynamic localizeDynamic(String key, {LocalizationParser parser}) => localization.localizeDynamic(key, parser: parser);

  ///[BaseLocalization.extractLocalization]
  @protected
  String extractLocalization(dynamic data, {String iso2Locale, String defaultLocale}) => localization.extractLocalization(data, iso2Locale: iso2Locale, defaultLocale: defaultLocale);
}
