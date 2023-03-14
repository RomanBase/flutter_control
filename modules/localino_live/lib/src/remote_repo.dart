part of localino_live;

class _RemoteRepo {
  static const url = 'https://api.localino.app/v1';

  Uri spaceUrl(String space) => Uri.parse('${url}/$space');

  Uri projectUrl(String space, String project) => Uri.parse('${url}/$space/$project');

  Uri localeUrl(String space, String project, String locale, [int? timestamp]) => Uri.parse('${url}/$space/$project/locale/$locale' + (timestamp == null ? '' : '?timestamp=$timestamp'));

  Map<String, String> get headers => <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
      };

  http.Client get _client => http.Client();

  Future<http.Response> getSpace(String space) => _client.get(spaceUrl(space), headers: headers);

  Future<http.Response> getProject(String space, String project) => _client.get(projectUrl(space, project), headers: headers);

  Future<http.Response> getLocale(String space, String project, String locale, [int? timestamp]) => _client.get(localeUrl(space, project, locale), headers: headers);
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
