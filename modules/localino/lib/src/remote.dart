part of localino;

abstract class LocalinoRemoteApi {
  /// Returns list of active locales from remote server.
  /// ['en_US', 'es_ES', 'cs_CZ']
  Future<List<String>> getLocales();

  /// Returns translations for given [locale] from remote server.
  /// Filter [timestamp] to specify border and return only changes.
  /// Filter [version] to fetch versioned translations.
  /// {'app_name': 'Super app', 'another_key': 'another translation'}
  Future<Map<String, dynamic>> getTranslations(String locale, {DateTime? timestamp, String? version});

  /// Returns config for given [locale] from remote server.
  /// Filter [timestamp] to specify border and return only changes.
  /// {'app_name': 'Super app', 'another_key': 'another translation'}
  Future<Map<String, dynamic>> getRemoteConfig();

  /// Returns translations for given [locale] from local cache.
  /// {'app_name': 'Super app', 'another_key': 'another translation'}
  Future<Map<String, dynamic>> loadLocalCache(String locale);

  /// Stores [translations] to local cache.
  Future<void> storeLocalCache(String locale, Map<String, dynamic> translations, [DateTime? timestamp]);
}

class LocalinoRemote with PrefsProvider implements Disposable {
  LocalinoRemoteOptions? options;

  Localino? _instance;

  Localino get instance => _instance ?? LocalinoProvider.instance;

  set instance(Localino? instance) => _instance = instance;

  LocalinoRemoteApi? get _api => Control.get<LocalinoRemoteApi>(args: options);

  Disposable? _sub;

  bool _enable = false;

  bool get enabled => _enable;

  LocalinoRemote({Localino? instance, this.options}) : _instance = instance;

  bool _ensureModule() {
    if (!_enable) {
      printDebug('LocalinoRemote is disabled');
      return false;
    }

    assert(
      _api != null,
      '[LocalinoRemoteApi] Module NOT FOUND.\n'
      'Check your pubspec.yaml and dependency of [localino_remote] package.\n'
      'Ensure that localino_remote is initialized with [Control]',
    );

    return _api != null;
  }

  void initialize({Map<String, DateTime>? locales, bool remoteSync = false, bool initialFetch = true}) {
    _enable = _api != null;

    if (locales != null) {
      mountLocalCache(locales);
    }

    if (remoteSync) {
      enableAutoSync(initialFetch: initialFetch);
    }
  }

  void disable() {
    _enable = false;
    _sub?.dispose();
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

    return _enable;
  }

  Future<bool> loadRemoteTranslations({String? locale, DateTime? timestamp}) async {
    if (!_ensureModule()) {
      return false;
    }

    locale ??= instance.locale;
    timestamp ??= lastUpdate(locale);

    printDebug('Localino: fetch remote locale: $locale $timestamp | ${options?.space}, ${options?.project}');

    if (locale == LocalinoAsset.empty.locale) {
      printDebug('Localino: fetch aborted with invalid locale: $locale');
      return false;
    }

    final now = DateTime.now().toUtc();
    final result = await _api!.getTranslations(locale, timestamp: timestamp).catchError((err) {
      printDebug(err);
      return <String, dynamic>{};
    });

    if (result.isNotEmpty) {
      _updateLocalSync({locale: timestamp = now});
      _updateLocalization(locale, result);

      await _api!.storeLocalCache(locale, result, timestamp).catchError((err) {
        printDebug(err);
      });
    }

    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>> loadLocalTranslations({String? locale}) async {
    if (!_ensureModule()) {
      return {};
    }

    final data = await _api!.loadLocalCache(locale ?? instance.locale).catchError((err) {
      printDebug(err);
      return <String, dynamic>{};
    });

    return data;
  }

  void _updateLocalization(String locale, Map<String, dynamic> translations) {
    if (instance.locale == locale) {
      instance.setData(translations, notify: true);
    }
  }

  DateTime? lastUpdate(String locale) => _getLocalSync()[locale];

  Map<String, DateTime> _getLocalSync() => Parse.toKeyMap<String, DateTime>(prefs.getJson(Localino.preference_key_sync), (key, value) => key as String, converter: (value) => Parse.date(value)!);

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
      prefs.setJson(Localino.preference_key_sync, data.map((key, value) => MapEntry(key, value.toIso8601String())));
    }
  }

  void mountLocalCache(Map<String, DateTime> locales) async {
    if (!_ensureModule()) {
      return;
    }

    final data = _getLocalSync();

    bool changed = false;
    data.forEach((key, value) async {
      if (!locales.containsKey(key) || value.isBefore(locales[key]!)) {
        await _api!.storeLocalCache(key, {});
        data[key] = value;
        changed = true;
      }
    });

    locales.forEach((key, value) {
      if (!data.containsKey(key)) {
        data[key] = value;
        changed = true;
      }
    });

    if (changed) {
      prefs.setJson(Localino.preference_key_sync, data.map((key, value) => MapEntry(key, value.toIso8601String())));
    }
  }

  @override
  void dispose() {
    _enable = false;
    _sub?.dispose();
  }
}
