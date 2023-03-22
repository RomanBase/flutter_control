part of localino_live;

class _LocalinoLiveApi implements LocalinoRemoteApi {
  _RemoteRepo get remoteRepo => _RemoteRepo();

  _LocalRepo get localRepo => _LocalRepo();

  final LocalinoRemoteOptions options;

  _LocalinoLiveApi(this.options);

  //TODO: config not implemented on Localino side
  @override
  Future<Map<String, dynamic>> getRemoteConfig() async {
    final response =
        await remoteRepo.getProject(options.space, options.project);

    if (response.isValid) {
      return response.json;
    }

    throw response;
  }

  @override
  Future<List<String>> getLocales() async {
    final response =
        await remoteRepo.getProject(options.space, options.project);

    if (response.isValid) {
      final json = response.json;

      return Parse.toList(json['locale'], converter: (data) {
        final country = data['country_code'];
        final language = data['language_code']!;

        if (country != null) {
          return '${country}_${language}';
        }

        return language;
      });
    }

    throw response;
  }

  //TODO: version not implemented on Localino side
  @override
  Future<Map<String, dynamic>> getTranslations(String locale,
      {DateTime? timestamp, String? version}) async {
    final response = await remoteRepo.getLocale(options.space, options.project,
        locale, timestamp?.toUtc().millisecondsSinceEpoch);

    if (response.isValid) {
      return response.json;
    }

    throw response;
  }

  @override
  Future<Map<String, dynamic>> loadLocalCache(String locale) =>
      localRepo.loadLocaleFromCache(options.space, locale);

  @override
  Future<void> storeLocalCache(String locale, Map<String, dynamic> translations,
      [DateTime? timestamp]) async {
    if (translations.isEmpty) {
      await localRepo.deleteLocaleCache(options.space, locale);
    } else {
      final data = await loadLocalCache(locale);
      data.addAll(translations);

      await localRepo.storeLocaleToCache(options.space, locale, data);
    }
  }
}
