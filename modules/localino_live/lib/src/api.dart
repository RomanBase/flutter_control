part of localino_live;

/// An implementation of [LocalinoRemoteApi] that uses the Localino REST API.
class _LocalinoLiveApi implements LocalinoRemoteApi {
  /// The remote repository for fetching data from the API.
  LocalinoRemoteRepo get remoteRepo => LocalinoLive.repo(options.access);

  /// The local repository for caching data on the device.
  LocalinoLocalRepo get localRepo => LocalinoLive.cache();

  /// The remote options containing space, project, and access credentials.
  final LocalinoRemoteOptions options;

  _LocalinoLiveApi(this.options);

  @override
  Future<Map<String, dynamic>> getRemoteSetup(
      String space, String project) async {
    final response = await remoteRepo.getSetup(space, project);

    if (response.isValid) {
      return response.json;
    }

    throw response.body;
  }

  //TODO: [version] not implemented on Localino side
  @override
  Future<Map<String, dynamic>> getRemoteTranslations(String locale,
      {DateTime? timestamp, String? version}) async {
    final response = await remoteRepo.getLocale(options.space, options.project,
        locale, timestamp?.toUtc().millisecondsSinceEpoch);

    if (response.isValid) {
      return response.json;
    }

    throw response.body;
  }

  @override
  Future<Map<String, dynamic>> getLocalCache(String locale) async {
    if (kIsWeb) {
      printDebug('LocalinoLive cache is not supported on web');
      return {};
    }

    return localRepo.loadLocaleFromCache(
        options.space, options.project, locale);
  }

  @override
  Future<void> setLocalCache(String locale, Map<String, dynamic> translations,
      [DateTime? timestamp]) async {
    if (kIsWeb) {
      printDebug('LocalinoLive cache is not supported on web');
      return;
    }

    if (translations.isEmpty) {
      await localRepo.deleteLocaleCache(options.space, options.project, locale);
    } else {
      final data = await getLocalCache(locale);
      data.addAll(translations);

      await localRepo.storeLocaleToCache(
          options.space, options.project, locale, data);
    }
  }
}
