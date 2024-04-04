import 'package:flutter_control/control.dart';
import 'package:localino_live/localino_live.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class Counter extends BaseControl with ObservableComponent<int> {
  @override
  void onInit(Map args) {
    super.onInit(args);

    value = args.getArg<int>(defaultValue: 0);
  }

  void increment() => value = value! + 1;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Control.initControl(
      debug: true,
      modules: [
        RoutingModule([
          ControlRoute.build<SecondPage>(builder: (_) => SecondPage()),
        ]),
        LocalinoModule(LocalinoLive.options(
          remoteSync: false,
        )),
      ],
      factories: {
        Counter: (_) => Counter(),
      },
      initAsync: () async {
        await Future.delayed(Duration(seconds: 1));
      },
    );

    return ControlRoot(
      theme: ThemeConfig(themes: {
        Brightness.light: () => ThemeData.from(colorScheme: ColorScheme.light()),
        Brightness.dark: () => ThemeData.from(colorScheme: ColorScheme.dark()),
      }),
      states: [
        AppState.init.build((context) => InitLoader.of(builder: (_) => Center(child: Text('init')))),
        AppState.onboarding.build((context) => OnboardingPage()),
        AppState.main.build((context) => MainPage()),
      ],
      builder: (context, home) => MaterialApp(
        title: 'Flutter Demo',
        home: home,
        onGenerateRoute: (settings) => context.generateRoute(settings),
        theme: context<ThemeConfig>()?.getPreferredTheme(),
        locale: LocalinoProvider.instance.currentLocale,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('onboarding'),
      ),
    );
  }
}

class MainPage extends SingleControlWidget<Counter> {
  @override
  Widget build(CoreContext context, Counter counter) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalinoProvider.instance.localize('app_name')),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                if (ThemeConfig.preferredTheme == 'light') {
                  context.root<ThemeConfig>()?.changeTheme(Brightness.dark);
                } else {
                  context.root<ThemeConfig>()?.changeTheme(Brightness.light);
                }
              },
              child: Text('Theme: ${ThemeConfig.preferredTheme}'),
            ),
            ElevatedButton(
              onPressed: () {
                LocalinoProvider.instance.changeLocale(LocalinoProvider.instance.locale == 'en_US' ? 'cs_CZ' : 'en_US');
              },
              child: Text('Locale: ${LocalinoProvider.instance.locale}'),
            ),
            ElevatedButton(
              onPressed: () => context.routeOf<SecondPage>()?.openRoute(args: counter),
              child: Text('Open Next'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Text('${counter.value}'),
        onPressed: () => counter.increment(),
      ),
    );
  }
}

class SecondPage extends ControlWidget {
  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    context<Counter>(value: () => Control.get<Counter>(args: args)!);
  }

  @override
  Widget build(CoreContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('This is second page'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                if (ThemeConfig.preferredTheme == 'light') {
                  context.root.changeTheme(Brightness.dark);
                } else {
                  context.root.changeTheme(Brightness.light);
                }
              },
              child: Text('Theme: ${ThemeConfig.preferredTheme}'),
            ),
            ElevatedButton(
              onPressed: () {
                LocalinoProvider.instance.changeLocale(LocalinoProvider.instance.locale == 'en_US' ? 'cs_CZ' : 'en_US');
              },
              child: Text('Locale: ${LocalinoProvider.instance.locale}'),
            ),
            ElevatedButton(
              onPressed: () => context.routeOf<SecondPage>()?.openRoute(args: context<Counter>()?.value),
              child: Text('Open Next'),
            ),
          ],
        ),
      ),
      floatingActionButton: ControlBuilder<int>(
        control: context<Counter>(),
        builder: (_, value) {
          return FloatingActionButton(
            child: Text('$value'),
            onPressed: () => context<Counter>()?.increment(),
          );
        },
        noData: (_) => BackButton(),
      ),
    );
  }
}
