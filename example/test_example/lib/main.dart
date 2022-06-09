import 'package:flutter_control/control.dart';
import 'package:flutter_control_example/cross_page.dart';

import 'cards_controller.dart';
import 'cards_page.dart';
import 'menu_page.dart';
import 'settings_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      localization: LocalinoConfig(
        defaultLocale: 'en',
        locales: LocalinoAsset.map(
          // References to assets/localization/en.json
          locales: [
            'en',
            'cs',
          ],
        ),
      ),
      entries: {
        'cards': CardsController(),
      },
      initializers: {
        DetailController: (args) =>
            DetailController(Parse.getArg<CardModel>(args)),
        CrossControl: (args) => CrossControl(),
      },
      injector: Injector.of({
        ControlTheme: (item, args) {
          item.assets = AssetPath(rootDir: 'assets');
        },
      }),
      routes: [
        ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()).path(
            name: (_) => ['settings', 'detail'],
            query: (_) => {'a': 1, 'b': 'A'}),
        ControlRoute.build<DetailPage>(
                identifier: 'detail', builder: (_) => DetailPage())
            .path(
                query: (args) =>
                    Uri.encodeComponent(Parse.getArg<CardModel>(args).title)),
      ],
      theme: ThemeConfig<MyTheme>(
        builder: (context) => MyTheme(context),
        initTheme: ThemeData,
        themes: MyTheme.themes,
      ),
      states: [
        AppState.onboarding.build(
          (context) => InitLoader.of(
            delay: Duration(seconds: 1),
            builder: (context) => Container(
              color: Colors.orange,
            ),
          ),
          transition: CrossTransition.fadeCross(duration: Duration(seconds: 2)),
        ),
        AppState.main.build((context) => MenuPage()),
        AppState.auth.build((context) => SettingsPage()),
      ],
      app: (setup, home) => MaterialApp(
        key: setup.key,
        theme: setup.theme,
        title: setup.title('app_name', 'Flutter Example'),
        home: home,
        onGenerateRoute: (settings) => ControlRoute.provider.generate(
          settings,
          active: setup.state == AppState.main,
          onGenerate: (settings) {
            final uri = Uri.parse(settings.name);

            return null;
          },
        ),
      ),
    );
  }
}

class MyTheme extends ControlTheme {
  @override
  final padding = 24.0;

  @override
  final paddingHalf = 12.0;

  final superColor = Colors.red;

  MyTheme(BuildContext context) : super(context);

  static Map<dynamic, Initializer<ThemeData>> get themes => {
        Brightness.light: (_) =>
            ThemeData.light().copyWith(primaryColor: Colors.green),
        Brightness.dark: (_) =>
            ThemeData.dark().copyWith(primaryColor: Colors.deepPurple),
        ThemeData: (_) => ThemeData(primaryColor: Colors.deepOrange),
      };
}
