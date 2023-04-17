part of localino_live;

class _RemoteRepo {
  //gcloud origin url: https://localino-app-rfwxdzufva-ew.a.run.app
  static const url = 'https://api.localino.app/$version';
  static const version = 'v1';

  final String? token;

  const _RemoteRepo(this.token);

  Uri spaceUrl(String space) => Uri.parse('$url/$space');

  Uri projectUrl(String space, String project) =>
      Uri.parse('$url/$space/$project');

  Uri setupUrl(String space, String project) =>
      Uri.parse('$url/$space/$project/setup');

  Uri localeUrl(String space, String project, String locale,
          [int? timestamp]) =>
      Uri.parse('$url/$space/$project/locale/$locale' +
          (timestamp == null ? '' : '?timestamp=$timestamp'));

  Map<String, String> get headers => <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        if (token != null) 'Access': token!,
      };

  http.Client get _client => http.Client();

  Future<http.Response> getSpace(String space) =>
      _client.get(spaceUrl(space), headers: headers);

  Future<http.Response> getProject(String space, String project) =>
      _client.get(projectUrl(space, project), headers: headers);

  Future<http.Response> getSetup(String space, String project) =>
      _client.get(setupUrl(space, project), headers: headers);

  Future<http.Response> getLocale(String space, String project, String locale,
          [int? timestamp]) =>
      _client.get(localeUrl(space, project, locale, timestamp),
          headers: headers);
}

extension _ResponseEx on http.Response {
  bool get isValid => (isOk || created) && bodyBytes.isNotEmpty;

  bool get isOk => statusCode == 200;

  bool get created => statusCode == 201;

  bool get badRequest => statusCode == 400;

  bool get notAuthorized => statusCode == 401;

  bool get notFound => statusCode == 404;

  dynamic get json => jsonDecode(body);
}
