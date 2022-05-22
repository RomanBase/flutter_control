import 'package:control_config/config.dart';
import 'package:control_core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localino/localino.dart';

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  test('init standalone', () async {
    Control.factory.dispose();

    final initialized = await LocalinoModule.initWithControl(LocalinoConfig(
      locales: LocalinoAsset.map(locales: ['en', 'cs']),
      initLocale: false, // no assets in test so localino can't be initialized.
    ));

    await Control.factory.onReady();

    Control.factory.printDebugStore();

    expect(initialized, isTrue);
  });

  test('init with control', () async {
    Control.factory.dispose();

    final initialized = Control.initControl(
      modules: [
        LocalinoModule(LocalinoConfig(
          locales: LocalinoAsset.map(locales: ['en', 'cs']),
          initLocale: false, // no assets in test so localino can't be initialized.
        )),
      ],
    );

    await Control.factory.onReady();

    Control.factory.printDebugStore();

    expect(initialized, isTrue);
  });
}
