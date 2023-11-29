import 'dart:io';

import 'package:build/build.dart';
import 'package:localino_builder/build.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  print('Localino Run Binary');

  final yaml = await File('build.yaml').readAsString();
  final config = loadYaml(yaml);

  final options = _findLocalinoOptions(config);

  if (options == null) {
    print('Localino Config Not Found');
    return;
  }

  build(BuilderOptions({...options}));
}

Map? _findLocalinoOptions(Map data) {
  if (data.containsKey('localino_builder')) {
    return data['localino_builder']['options'];
  }

  for (final key in data.keys) {
    final options = _findLocalinoOptions(data[key]);

    if (options != null) {
      return options;
    }
  }

  return null;
}
