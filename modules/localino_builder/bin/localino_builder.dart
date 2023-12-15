import 'dart:io';

import 'package:build/build.dart';
import 'package:localino_builder/build.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  print('Localino Run Binary');

  Map? options = _parseArgs(arguments);

  if (options == null) {
    final yaml = await File('build.yaml').readAsString();
    final config = loadYaml(yaml);

    options = _parseBuildYaml(config);
  }

  if (options == null) {
    print('Localino Config Not Found');
    return;
  }

  build(BuilderOptions({...options}));
}

Map? _parseArgs(List<String> args) {
  final userArg = args.indexOf('-u');
  final projectArg = args.indexOf('-sp');

  if (userArg < 0 || projectArg < 0) {
    return null;
  }

  final access = args[userArg + 1];
  final project = args[projectArg + 1].split(':');

  return {
    'access': access,
    'space': project.first,
    'project': project.last,
  };
}

Map? _parseBuildYaml(Map data) {
  if (data.containsKey('localino_builder')) {
    return data['localino_builder']['options'];
  }

  for (final key in data.keys) {
    final options = _parseBuildYaml(data[key]);

    if (options != null) {
      return options;
    }
  }

  return null;
}
