import 'package:flutter_control/core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'main_page.dart';
import 'settings_page.dart';

void main() {
  Control.initControl(
    localization: LocalizationConfig(
      locales: {
        'en': 'assets/localization/en.json',
        'es': 'assets/localization/es.json',
      },
    ),
    routes: [
      ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
    ],
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ActionBuilder<Locale>(
      control: ActionControl.provider(key: Locale, defaultValue: Locale('en')),
      builder: (context, value) {
        return MaterialApp(
          title: "Localization - Flutter Control",
          locale: value,
          supportedLocales: Control.localization().delegate.supportedLocales(),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            Control.localization().delegate,
          ],
          home: MainPage(),
        );
      },
    );
  }
}
