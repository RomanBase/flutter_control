part of localino;

/// Json/Map based localization.
class Localino extends ChangeNotifier with PrefsProvider implements Disposable {
  /// Key of shared preference where preferred locale is stored.
  static const String preference_key = 'control_locale';

  /// Key of shared preference where config is stored.
  static const String preference_key_sync = 'control_locale_sync';

  /// Current localization data.
  final _data = <String, dynamic>{};

  /// List of available localization assets.
  /// [LocalinoAsset] defines language and asset path to file with localization data.
  late List<LocalinoAsset> assets;

  /// Default locale.
  /// This locale should be loaded first, because data can contains some shared/non translatable values (links, captions, etc.).
  String defaultLocale = WidgetsBinding.instance.window.locale.toString();

  Future<Map<String, dynamic>> Function()? localData;

  /// Checks if this localization is main and will broadcast [LocalinoArgs] changes with [Localino] key.
  /// Only one localization should be main !
  bool main = false;

  /// Current locale key.
  String? _locale;

  /// Enables debug mode for localization.
  /// When localization key isn't found for given locale, then [localize] returns key and current locale (key_locale).
  bool debug = true;

  /// Loading localization data is async, so check this to prevent concurrent loading.
  bool loading = false;

  /// Custom func for [extractLocalization].
  /// Default extractor is [Map] based: {'locale': 'value'}.
  LocalizationExtractor? _mapExtractor;

  /// Custom param decorator.
  /// Default decorator is [ParamDecorator.curl]: 'city' => '{city}'.
  ParamDecoratorFormat _paramDecorator = ParamDecorator.curl;

  /// The system-reported default locale of the device.
  Locale get deviceLocale => WidgetsBinding.instance.window.locale;

  /// The full system-reported supported locales of the device.
  List<Locale> get deviceLocales => WidgetsBinding.instance.window.locales;

  /// Returns currently loaded locale.
  String get locale => _locale ?? defaultLocale;

  /// Returns currently loaded locale.
  Locale? get currentLocale => getLocale(locale);

  /// Returns best possible country code based on [currentLocale] and [deviceLocale].
  String? get currentCountry =>
      currentLocale?.countryCode ??
      (_locale == null
              ? deviceLocale
              : deviceLocales.firstWhere(
                  (element) => locale.startsWith(element.languageCode),
                  orElse: () => deviceLocale))
          .countryCode;

  /// Is [true] if any data are stored in localization map.
  bool get isActive => _data.length > 0;

  /// Is [true] if any [LocalinoAsset] is valid.
  bool get hasValidAsset => assets.any((element) => element.isValid);

  /// Is [true] if localization can load default locale data.
  bool get isDirty => !loading && !isActive && hasValidAsset;

  /// Json/Map based localization.
  ///
  /// [defaultLocale] - should be loaded first, because data can contains some shared/non translatable values (links, captions, etc.).
  /// [assets] - defines locales and asset path to files with localization data.
  Localino._();

  Localino.instance(this.defaultLocale, this.assets);

  /// Creates new localization object based on this localization settings.
  Localino instanceOf(List<LocalinoAsset> assets) {
    return Localino._()
      ..defaultLocale = defaultLocale
      ..assets = assets;
  }

  void _setup(String defaultLocale, List<LocalinoAsset> assets,
      Future<Map<String, dynamic>> Function() localData) {
    this.defaultLocale = defaultLocale;
    this.assets = assets;
    this.localData = localData;
  }

  /// Should be called first.
  /// Loads initial localization data - [getSystemLocale] is used to get preferred locale.
  ///
  /// [loadDefaultLocale] - loads [defaultLocale] before preferred locale.
  /// [handleSystemLocale] - listen for default locale of the device. Whenever this locale is changed, localization will change locale (but only when there is no preferred locale).
  Future<LocalinoArgs> init({
    bool loadDefaultLocale = true,
    bool handleSystemLocale = false,
    bool handleRemoteLocale = false,
    String? stableLocale,
  }) async {
    if (!hasValidAsset) {
      printDebug('Localino initialization failed: no valid asset found.');
      return LocalinoArgs(
        locale: '#',
        isActive: false,
        changed: false,
        source: 'invalid',
      );
    }

    this.main = main;
    loading = true;

    await prefs.mount();

    LocalinoArgs? args;

    if (stableLocale != null) {
      printDebug('Localino initializing stable locale: $stableLocale');
      args = await loadLocalizationData(stableLocale);
    }

    if (loadDefaultLocale) {
      printDebug('Localino initializing default locale: $defaultLocale');
      args = await loadDefaultLocalization();
    }

    final systemLocale = getSystemLocale();
    if (!isSystemLocaleActive(nullOk: false) && systemLocale != defaultLocale) {
      printDebug('Localino initializing system locale: $systemLocale}');
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

    if (handleRemoteLocale) {
      LocalinoProvider.remote.enableAutoSync();
    }

    return args ??
        LocalinoArgs(
          locale: '#',
          isActive: false,
          changed: false,
          source: 'invalid',
        );
  }

  /// Looks for best suited asset locale to device supported locale.
  ///
  /// Returns system locale or null if no locale found.
  String? getAvailableAssetLocaleForDevice() {
    final locales = deviceLocales;

    for (Locale loc in locales) {
      if (isLocalizationAvailable(loc.toString())) {
        return loc.toString();
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
        defaultLocale;
  }

  /// Checks if preferred locale is loaded.
  ///
  /// [nullOk] Returns [true] if no [locale] is set.
  bool isSystemLocaleActive({bool nullOk = true}) {
    if (_locale == null && nullOk) {
      return true;
    }

    final pref = getSystemLocale();

    return isActive && isLocaleEqual(pref, locale);
  }

  /// Removes preferred locale stored in shared preferences.
  ///
  /// [loadSystemLocale] - to load new system preferred locale.
  /// Returns result of localization change [LocalinoArgs] or just result of reset prefs [bool].
  /// Result of localization change is send to global broadcast with [Localino] key.
  Future<dynamic> resetPreferredLocale({bool loadSystemLocale = false}) async {
    prefs.set(preference_key, null);

    if (loadSystemLocale) {
      return changeToSystemLocale();
    }

    return true;
  }

  /// Changes localization to [defaultLocale].
  ///
  /// [resetPreferred] - to reset preferred locale stored in shared preferences.
  /// Returns result of localization change [LocalinoArgs].
  /// Result of localization change is also broadcast to global object stream with [Localino] key.
  Future<LocalinoArgs> loadDefaultLocalization({bool resetPreferred = false}) {
    if (resetPreferred) {
      resetPreferredLocale();
    }

    return changeLocale(defaultLocale, preferred: false);
  }

  /// Changes localization to system preferred language.
  ///
  /// [getSystemLocale] is used to get preferred locale.
  /// Returns result of localization change [LocalinoArgs].
  /// Result of localization change is send to global broadcast with [Localino] key.
  Future<LocalinoArgs> changeToSystemLocale(
      {bool resetPreferred = false}) async {
    loading = true;

    final locale = getSystemLocale();

    if (resetPreferred) {
      resetPreferredLocale();
    }

    return await changeLocale(locale, preferred: false);
  }

  /// Changes localization data inside this object for given [locale].
  /// Set [preferred] to store locale as system preferred into shared preferences.
  ///
  /// Returns result of localization change [LocalinoArgs].
  /// Result of localization change is send to global broadcast with [Localino] key.
  Future<LocalinoArgs> changeLocale(String locale,
      {bool preferred = true}) async {
    if (debug && locale == 'debug') {
      printDebug('Localino setting up DEBUG locale: #');
      return _setDebugLocale();
    }

    final args = await loadLocalizationData(locale);

    if (args.isActive) {
      _locale = args.locale;

      if (preferred) {
        if (main) {
          prefs.set(preference_key, _locale);
        } else {
          printDebug(
              'Only \'main\' localization can change preferred locale !!!');
        }
      }

      _notify(args);
    }

    return args;
  }

  LocalinoArgs _setDebugLocale() {
    clear();
    _locale = '#';

    final args = LocalinoArgs(
      locale: '#',
      isActive: true,
      changed: true,
      source: 'debug',
    );

    _notify(args);

    return args;
  }

  /// Notify and broadcast changes.
  void _notify(LocalinoArgs args) {
    notifyListeners();
    _broadcastArgs(args);
  }

  /// Broadcast localization changes.
  void _broadcastArgs(LocalinoArgs args) {
    if (main) {
      BroadcastProvider.broadcast<Localino>(value: args);
    }
  }

  /// Loads localization data of [locale] key.
  /// Can be used to load non-translatable data.
  /// Returns result of localization change [LocalinoArgs].
  Future<LocalinoArgs> loadLocalizationData(String locale) async {
    loading = true;

    if (!isLocalizationAvailable(locale)) {
      print('Localization not available: $locale');
      loading = false;
      return LocalinoArgs(
        locale: locale,
        isActive: false,
        changed: false,
        source: 'asset',
      );
    }

    if (isLocaleEqual(_locale, locale)) {
      loading = false;
      print('Localization is already loaded: $locale');
      return LocalinoArgs(
        locale: locale,
        isActive: true,
        changed: false,
        source: 'asset',
      );
    }

    final args = await _loadAssetLocalization(locale, getAsset(locale));

    loading = false;

    return args;
  }

  /// Loads localization from asset file for given [locale] and [asset].
  Future<LocalinoArgs> _loadAssetLocalization(
      String locale, LocalinoAsset? asset) async {
    if (asset == null || !asset.isValid) {
      print('Localization asset is not valid: $asset');
      return LocalinoArgs(
        locale: locale,
        isActive: false,
        changed: false,
        source: 'asset',
      );
    }

    try {
      final json = await rootBundle
          .loadString(asset.path!, cache: false)
          .catchError((err) {
        printDebug(err);
        return '{}';
      });

      final assets = jsonDecode(json);
      final locals = await localData?.call();

      final data = _mergeData([assets, locals]);

      if (data.isNotEmpty) {
        data.forEach((key, value) => _data[key] = value);

        print('Localization changed to: $asset');

        final args = LocalinoArgs(
          locale: asset.locale,
          isActive: true,
          changed: true,
          source: 'asset',
        );

        return args;
      }
    } catch (ex) {
      printDebug(ex.toString());
    }

    print('Localization failed to change: $asset');

    return LocalinoArgs(
      locale: locale,
      isActive: false,
      changed: false,
      source: 'asset',
    );
  }

  Map<String, dynamic> _mergeData(Iterable<Map<String, dynamic>?> data) {
    final map = <String, dynamic>{};

    data.forEach((element) {
      if (element != null && element.isNotEmpty) {
        map.addAll(element);
      }
    });

    return map;
  }

  /// Returns [true] if localization file is available and is possible to load it.
  /// Do not check physical existence of file !
  bool isLocalizationAvailable(String locale) =>
      getAsset(locale)?.isValid ?? false;

  /// Checks if [a] and [b] is same or if this values points to same asset path.
  /// Comparing 'en' and 'en_US' can be true because they can point to same asset file.
  bool isLocaleEqual(String? a, String? b) {
    if (a == null || b == null) {
      return false;
    }

    if (a == b) {
      return true;
    }

    return getAsset(a)?.path == getAsset(b)?.path;
  }

  /// Tries to find asset for given [locale].
  /// Locale of 'en' and 'en_US' can point to same asset file.
  ///
  /// Returns [LocalinoAsset] for given [locale] or null if localization asset is not available.
  LocalinoAsset? getAsset(String? locale) {
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

  /// Tries to find [Locale] is assets for given [locale].
  /// Locale of 'en' and 'en_US' can point to same asset file, so resulted [Locale] for 'en_US' can be [Locale('en')] if only 'en.json' file exists.
  ///
  /// Returns [Locale] for given [locale] or null if localization asset is not available.
  Locale? getLocale(String? locale) => getAsset(locale)?.toLocale();

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
  String localizePlural(String key, int plural, [Map<String, String>? params]) {
    if (_data.containsKey(key)) {
      if (_data[key] is Map) {
        final data = _data[key];
        final nums = <int>[];

        data.forEach(
            (num, value) => nums.add(Parse.toInteger(num, defaultValue: -1)));
        nums.sort();

        String? output;

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

  /// Tries to localize text by given [key] and [value].
  ///
  /// child: {
  ///   "male": "boy",
  ///   "female": "girl",
  ///   "other": "child"
  /// }
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  String localizeValue(String key, String value) {
    if (_data.containsKey(key)) {
      if (_data[key] is Map) {
        final map = _data[key] as Map;

        if (map.containsKey(value)) {
          return map[value];
        }

        if (map.containsKey('other')) {
          return map['other'];
        }
      }

      return _data[key];
    }

    return debug ? '$key[$value]_$_locale' : '';
  }

  /// Tries to localize text by given [key].
  ///
  /// days: [
  ///   "monday", "tuesday", "wednesday"
  /// ]
  ///
  /// Enable/Disable debug mode to show/hide missing localizations.
  Iterable<String> localizeList(String key) {
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
      {LocalizationParser? parser, dynamic defaultValue}) {
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
      {String? locale, String? defaultLocale}) {
    locale ??= this.locale;
    defaultLocale ??= this.defaultLocale;

    if (_mapExtractor != null) {
      return _mapExtractor!(data, locale, defaultLocale);
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
  void setData(Map<String, dynamic> data, {bool notify = false}) async {
    data.forEach((key, value) => _data[key] = value);

    if (notify) {
      _notify(LocalinoArgs(
        locale: locale,
        isActive: true,
        changed: false,
        source: 'runtime',
      ));
    }
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

  /// Delegate of [Localino] to use this localization as [LocalizationsDelegate].
  ///
  /// Use [LocalizationProvider.of(context)] to find delegate in current widget scope.
  LocalinoDelegate get delegate => LocalinoDelegate(this);

  @override
  void dispose() {
    super.dispose();

    clear();
  }
}
