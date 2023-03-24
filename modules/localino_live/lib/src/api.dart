part of localino_live;

class _LocalinoLiveApi implements LocalinoRemoteApi {
  _RemoteRepo get remoteRepo => _RemoteRepo();

  _LocalRepo get localRepo => _LocalRepo();

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

  //TODO: version not implemented on Localino side
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
