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
      initLocale: 'en',
      locales: LocalizationAsset.build(
        locales: [
          'en',
          'es',
        ],
      ),
      routes: [
        ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
      ],
      root: (context, value) => MainPage(),
      app: (context, key, home) {
        return MaterialApp(
          key: key,
          home: home,
          title: "Localization - Flutter Control",
        );
      },
    );
  }
}
