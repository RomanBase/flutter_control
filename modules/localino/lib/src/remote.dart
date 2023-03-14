part of localino;

abstract class LocalinoRemoteApi {
  /// Returns list of active locales from remote server.
  /// ['en_US', 'es_ES', 'cs_CZ']
  Future<List<String>> getLocales();

  /// Returns translations for given [locale] from remote server.
  /// Filter [timestamp] to specify border and return only changes.
  /// Filter [version] to fetch versioned translations.
  /// {'app_name': 'Super app', 'another_key': 'another translation'}
  Future<Map<String, dynamic>> getTranslations(String locale,
      {DateTime? timestamp, String? version});

  /// Returns config for given [locale] from remote server.
  /// Filter [timestamp] to specify border and return only changes.
  /// {'app_name': 'Super app', 'another_key': 'another translation'}
  Future<Map<String, dynamic>> getRemoteConfig();

  /// Returns translations for given [locale] from local cache.
  /// {'app_name': 'Super app', 'another_key': 'another translation'}
  Future<Map<String, dynamic>> loadLocalCache(String locale);

  /// Stores [translations] to local cache.
  Future<void> storeLocalCache(
      String locale, Map<String, dynamic> translations);
}

class LocalinoRemote with PrefsProvider {
  LocalinoRemoteOptions? options;

  Localino? _instance;

  Localino get instance => _instance ?? LocalinoProvider.instance;

  set instance(Localino? instance) => _instance = instance;

  LocalinoRemoteApi? get _api => Control.get<LocalinoRemoteApi>(args: options);

  Disposable? _sub;

  LocalinoRemote({Localino? instance, this.options}) : _instance = instance;

  bool _ensureModule() {
    assert(
      _api != null,
      '[LocalinoRemoteApi] Module NOT FOUND.'
      'Check your pubspec.yaml and dependency of [localino_remote] package.'
      'Ensure that localino_remote is initialized with [Control]',
    );

    return _api != null;
  }

  Future<bool> enableAutoSync({bool initialFetch = true}) async {
    if (_sub != null) {
      printDebug('Remote sync is already initialized');
      return false;
    }

    _sub = LocalinoProvider.subscribe((value) {
      if (value != null && value.changed) {
        loadRemoteTranslations(locale: value.locale);
      }
    });

    if (initialFetch) {
      return loadRemoteTranslations();
    }

    return false;
  }

  Future<bool> loadRemoteTranslations(
      {String? locale, DateTime? timestamp}) async {
    if (!_ensureModule()) {
      return false;
    }

    locale ??= instance.locale;
    timestamp ??= lastUpdate(locale);

    printDebug(
        'Localino: fetch remote locale: $locale $timestamp | ${options?.space}, ${options?.project}');

    if (locale == LocalinoAsset.empty.locale) {
      printDebug('Localino: fetch aborted with invalid locale: $locale');
      return false;
    }

    final now = DateTime.now().toUtc();
    final result = await _api!
        .getTranslations(locale, timestamp: timestamp)
        .catchError((err) {
      printDebug(err);
      return <String, dynamic>{};
    });

    if (result.isNotEmpty) {
      _updateLocalSync({locale: now});
      _updateLocalization(locale, result);
    }

    await _api!.storeLocalCache(locale, result).catchError((err) {
      printDebug(err);
    });

    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>> loadLocalTranslations({String? locale}) async {
    if (!_ensureModule()) {
      return {};
    }

    return _api!.loadLocalCache(locale ?? instance.locale);
  }

  void _updateLocalization(String locale, Map<String, dynamic> translations) {
    if (instance.locale == locale) {
      instance.setData(translations, notify: true);
    }
  }

  DateTime? lastUpdate(String locale) => _getLocalSync()[locale];

  Map<String, DateTime> _getLocalSync() => Parse.toKeyMap<String, DateTime>(
      prefs.getJson(Localino.preference_key_sync),
      (key, value) => key as String,
      converter: (value) => Parse.date(value)!);

  void _updateLocalSync(Map<String, DateTime> locales) {
    final data = _getLocalSync();

    bool changed = false;
    locales.forEach((key, value) {
      if (!data.containsKey(key) || data[key]!.isBefore(value)) {
        data[key] = value;
        changed = true;
      }
    });

    if (changed) {
      prefs.setJson(Localino.preference_key_sync,
          data.map((key, value) => MapEntry(key, value.toIso8601String())));
    }
  }

  void _clearLocalSync() => prefs.setJson(Localino.preference_key_sync, null);
}
