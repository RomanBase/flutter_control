import 'package:flutter_control/core.dart';

void main() {
  initStandaloneModule();
}

void initStandaloneModule() {
  var initialized = LocalinoModule.initControl(LocalinoConfig(
    locales: LocalinoAsset.map(locales: ['en', 'cs']),
  ));

  print('Control: $initialized');
  print('Localino: ${LocalinoProvider.instance}');
}

void initWithControl() {
  var initialized = Control.initControl(
    modules: [
      LocalinoModule(LocalinoConfig(
        locales: LocalinoAsset.map(locales: ['en', 'cs']),
      )),
    ],
  );

  print('Control: $initialized');
  print('Localino: ${LocalinoProvider.instance}');
}
