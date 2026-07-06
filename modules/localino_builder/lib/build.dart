import 'package:build/build.dart';
import 'package:localino_builder/localino_builder.dart';

Builder build(BuilderOptions options) {
  print('Localino Builder Started');

  return LocalinoBuilder(
    options.config['space'],
    options.config['project'],
    options.config['access'],
    generateKeys: _asBool(options.config['generate_keys']),
    reportUnused: _asBool(options.config['report_unused']),
  )..build(null);
}

/// Coerces a `build.yaml` / CLI option to `bool`. `loadYaml` yields `YamlBool`
/// or scalar strings, not `bool`, so accept both `true` and `'true'`.
bool _asBool(Object? value) => value == true || value == 'true';
