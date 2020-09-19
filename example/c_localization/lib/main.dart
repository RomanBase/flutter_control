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
