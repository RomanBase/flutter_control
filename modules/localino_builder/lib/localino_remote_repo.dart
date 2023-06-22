import 'dart:convert';

import 'package:http/http.dart' as http;

class LocalinoRemoteRepo {
  static const url = 'https://api.localino.app/$version';
  static const version = 'v1';

  late String token;
  late String space;
  late String project;

  LocalinoRemoteRepo();

  Uri spaceUrl(String space) => Uri.parse('$url/$space');

  Uri projectUrl(String space, String project) => Uri.parse('$url/$space/$project');

  Uri setupUrl(String space, String project) => Uri.parse('$url/$space/$project/setup');

  Uri localeUrl(String space, String project, String locale, [int? timestamp]) => Uri.parse('$url/$space/$project/locale/$locale' + (timestamp == null ? '' : '?timestamp=$timestamp'));

  Map<String, String> get headers => <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'Access': token,
      };

  http.Client get _client => http.Client();

  Future<String> getSpace() async {
    final response = await _client.get(spaceUrl(space), headers: headers);

    if (response.isValid) {
      return response.body;
    }

    throw response;
  }

  Future<String> getProject() async {
    final response = await _client.get(projectUrl(space, project), headers: headers);

    if (response.isValid) {
      return response.body;
    }

    throw response;
  }

  Future<String> getSetup() async {
    final response = await _client.get(setupUrl(space, project), headers: headers);

    if (response.isValid) {
      return response.body;
    }

    throw response;
  }

  Future<String> getLocale(String locale, [int? timestamp]) async {
    final response = await _client.get(localeUrl(space, project, locale, timestamp), headers: headers);

    if (response.isValid) {
      return response.body;
    }

    throw response;
  }
}

extension ResponseEx on http.Response {
  bool get isValid => (isOk || created) && bodyBytes.isNotEmpty;

  bool get isOk => statusCode == 200;

  bool get created => statusCode == 201;

  dynamic get json => jsonDecode(body);
}
