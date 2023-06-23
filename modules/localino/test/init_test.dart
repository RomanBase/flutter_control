import 'package:control_core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localino/localino.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('init standalone', () async {
    final initialized = await LocalinoModule.standalone(
      LocalinoOptions(
        config: LocalinoConfig(
          locales: LocalinoAsset.map(locales: ['en', 'cs']),
          initLocale:
              false, // no assets in test so localino can't be initialized.
        ),
      ),
    );

    await Control.factory.onReady();

    expect(initialized, isTrue);
    expect(LocalinoProvider.instance.availableLocales.length, 2);
    expect(LocalinoProvider.instance, isNotNull);
    expect(LocalinoProvider.remote, isNotNull);
    expect(LocalinoProvider.remote.enabled, isFalse);

    Control.factory.dispose();
  });

  test('init with control', () async {
    final initialized = Control.initControl(
      modules: [
        LocalinoModule(
          LocalinoOptions(
            config: LocalinoConfig(
              locales: LocalinoAsset.map(locales: ['en', 'cs']),
              initLocale:
                  false, // no assets in test so localino can't be initialized.
            ),
          ),
        ),
      ],
    );

    await Control.factory.onReady();

    expect(initialized, isTrue);
    expect(LocalinoProvider.instance.availableLocales.length, 2);
    expect(LocalinoProvider.instance, isNotNull);
    expect(LocalinoProvider.remote, isNotNull);
    expect(LocalinoProvider.remote.enabled, isFalse);

    Control.factory.dispose();
  });
}
