import 'package:flutter_control/core.dart';

class LocalizationAsset {
  final String iso2Locale;
  final String assetPath;

  LocalizationAsset(this.iso2Locale, this.assetPath);
}

class AppLocalization {
  final String defaultLocale;
  final List<LocalizationAsset> assets;

  String get locale => _locale;
  String _locale;

  Map<String, String> _data = Map();

  AppLocalization(this.defaultLocale, this.assets);

  Locale deviceLocale(BuildContext context) {
    return Localizations.localeOf(context, nullOk: true);
  }

  bool isLocalizationAvailable(String iso2Locale) {
    for (final asset in assets) {
      if (asset.iso2Locale == iso2Locale) {
        return true;
      }
    }

    return false;
  }

  Future<bool> changeLocale(String iso2Locale) async {
    if (!isLocalizationAvailable(iso2Locale)) {
      iso2Locale = defaultLocale;
    }

    _locale = iso2Locale;
    _initLocalization(_locale);

    return true;
  }

  void _initLocalization(String iso2Locale) {
    _data = Map();
  }

  String localize(String key) {
    if (_data.containsKey(key)) {
      return _data[key];
    }

    return "${key}_$_locale";
  }

  String extractLocalization(Map<String, String> map, String iso2Locale, String defaultLocale) {
    if (map.containsKey(iso2Locale)) {
      return map[iso2Locale];
    }

    if (map.containsKey(defaultLocale)) {
      return map[defaultLocale];
    }

    return '';
  }
}
