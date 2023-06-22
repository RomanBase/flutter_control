import 'package:build/build.dart';
import 'package:localino_builder/localino_builder.dart';

Builder build(BuilderOptions options) {
  print('LOCALINO Builder Started');

  return LocalinoBuilder(
    options.config['space'],
    options.config['project'],
    options.config['access'],
  )..build(null);
}
