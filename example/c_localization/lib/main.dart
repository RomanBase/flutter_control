import 'package:flutter_control/core.dart';

import 'main_page.dart';
import 'settings_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      localization: LocalizationConfig(
        defaultLocale: 'en',
        locales: LocalizationAsset.map(
          locales: [
            'en',
            'es',
          ],
        ),
      ),
      entries: {
        'side_test': SideLocalizationTest(),
        'empty_test': EmptyLocalizationTest(),
      },
      routes: [
        ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
      ],
      states: [
        AppState.main.build((context) => MainPage()),
      ],
      app: (setup, home) {
        return MaterialApp(
          key: setup.key,
          home: home,
          title: "Localization - Flutter Control",
        );
      },
    );
  }
}

class SideLocalizationTest implements Initializable {
  final localization = BaseLocalization(
      'en',
      LocalizationAsset.list(
        locales: [
          'en',
          'es',
        ],
      ));

  @override
  void init(Map args) {
    _loadLocalization();
  }

  void _loadLocalization() async {
    await Control.factory.onReady();

    final loadResult = await localization.init(
      loadDefaultLocale: false,
      handleSystemLocale: false,
    );

    printDebug(loadResult);
  }
}

class EmptyLocalizationTest implements Initializable {
  final localization = BaseLocalization('en', []);

  @override
  void init(Map args) {
    _loadLocalization();
  }

  void _loadLocalization() async {
    await Control.factory.onReady();

    final loadResult = await localization.init(
      loadDefaultLocale: true,
      handleSystemLocale: true,
    );

    printDebug(loadResult);
  }
}
