part of localino_live;

/// A repository for making HTTP requests to the Localino REST API.
class LocalinoRemoteRepo {
  //gcloud origin url: https://localino-app-rfwxdzufva-ew.a.run.app
  /// The base URL for the Localino API.
  static const url = 'https://api.localino.app/$version';

  /// The version of the Localino API.
  static const version = 'v1';

  /// The access token for authenticating with the API.
  final String? token;

  /// An optional HTTP client for making requests. Used for testing.
  final http.Client? client;

  const LocalinoRemoteRepo._(this.token, [this.client]);

  /// Builds the URL for a given [space].
  Uri spaceUrl(String space) => Uri.parse('$url/$space');

  /// Builds the URL for a given [project] within a [space].
  Uri projectUrl(String space, String project) =>
      Uri.parse('$url/$space/$project');

  /// Builds the URL for fetching the setup of a [project].
  Uri setupUrl(String space, String project) =>
      Uri.parse('$url/$space/$project/setup');

  /// Builds the URL for fetching a specific [locale] of a [project].
  Uri localeUrl(String space, String project, String locale,
          [int? timestamp]) =>
      Uri.parse('$url/$space/$project/locale/$locale' +
          (timestamp == null ? '' : '?timestamp=$timestamp'));

  /// Default headers for all API requests.
  Map<String, String> get headers => <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        if (token != null) 'Access': token!,
      };

  /// The active HTTP client.
  http.Client get _client => client ?? http.Client();

  /// Fetches details for a given [space].
  Future<http.Response> getSpace(String space) =>
      _client.get(spaceUrl(space), headers: headers);

  /// Fetches details for a given [project] within a [space].
  Future<http.Response> getProject(String space, String project) =>
      _client.get(projectUrl(space, project), headers: headers);

  /// Fetches the setup configuration for a [project].
  Future<http.Response> getSetup(String space, String project) =>
      _client.get(setupUrl(space, project), headers: headers);

  /// Fetches translations for a [locale] within a [project].
  /// An optional [timestamp] can be provided to fetch only updated translations.
  Future<http.Response> getLocale(String space, String project, String locale,
          [int? timestamp]) =>
      _client.get(localeUrl(space, project, locale, timestamp),
          headers: headers);
}

/// Extension on [http.Response] for convenience.
extension _ResponseEx on http.Response {
  /// Checks if the response was successful (200 or 201) and has content.
  bool get isValid => (isOk || created) && bodyBytes.isNotEmpty;

  /// Checks if the status code is 200 OK.
  bool get isOk => statusCode == 200;

  /// Checks if the status code is 201 Created.
  bool get created => statusCode == 201;

  /// Checks if the status code is 400 Bad Request.
  bool get badRequest => statusCode == 400;

  /// Checks if the status code is 401 Not Authorized.
  bool get notAuthorized => statusCode == 401;

  /// Checks if the status code is 404 Not Found.
  bool get notFound => statusCode == 404;

  /// Decodes the response body as JSON.
  dynamic get json => jsonDecode(body);
}
