import 'package:counter/src/loader_indicator.dart';
import 'package:counter/src/static_theme.dart';
import 'package:flutter_control/control.dart';
import 'package:localino/localino.dart';
import 'package:localino_live/localino_live.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class Counter extends BaseControl
    with ObservableComponent<int>, ReferenceCounter {
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
          ControlRoute.build<ThirdPage>(builder: (_) => ThirdPage()),
        ]),
        LocalinoModule(LocalinoOptions()),
        /*LocalinoModule(LocalinoLive.options(
          remoteSync: true,
        )),*/
      ],
      factories: {
        Counter: (_) => Counter(),
      },
      initAsync: () async {
        await Future.delayed(Duration(seconds: 1));
      },
    );

    return ControlRoot(
      theme: MaterialThemeConfig(
        themes: UITheme.factory,
      ),
      states: [
        AppState.init.build((context) =>
            InitLoader.of(builder: (_) => Center(child: Text('init')))),
        AppState.onboarding.build((context) => OnboardingPage()),
        AppState.main.build((context) => MainPage()),
      ],
      builders: [
        Localino,
      ],
      builder: (context, home) => MaterialApp(
        title: 'Flutter Demo',
        //home: home,
        onGenerateRoute: (settings) => context.generateRoute(settings,
            root: () => MaterialPageRoute(builder: (_) => home)),
        theme: context.themeConfig?.value,
        locale: LocalinoProvider.instance.currentLocale,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
      onSetupChanged: (context) {
        UITheme.scheme = context.themeConfig?.value.colorScheme;
        Intl.defaultLocale = LocalinoProvider.instance.locale;
      },
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
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    context.root.restoreNavigation();
  }

  @override
  Widget build(CoreContext context, Counter counter) {
    final theme = Theme.of(context);

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
                LocalinoProvider.instance.changeLocale(
                    LocalinoProvider.instance.locale == 'en_US'
                        ? 'cs_CZ'
                        : 'en_US');
              },
              child: Text('Locale: ${LocalinoProvider.instance.locale}'),
            ),
            ElevatedButton(
              onPressed: () =>
                  context.routeOf<SecondPage>()?.openRoute(args: counter),
              child: Text('Open Second'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Text(
          '${counter.value}',
          style: theme.textTheme.titleMedium,
        ),
        onPressed: () => counter.increment(),
      ),
    );
  }
}

class SecondPage extends ControlWidget with InitProvider {
  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    //We providing Counter only from MainPage
    context.value<bool>(key: 'second', value: args.containsKey(Counter));

    //[args] can contain [Counter] or [int].
    printDebug('Init Counter: from $args');
    final counter =
        context.use<Counter>(value: () => Control.get<Counter>(args: args)!);
    printDebug('Init Counter Value: ${counter.value}');
  }

  @override
  Widget build(CoreContext context) {
    final theme = context.theme;
    final counter = context<Counter>();
    final secondPage = context.value<bool>(key: 'second').value!;

    return GestureDetector(
      onTap: () => context.unfocus(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Text('This is ${secondPage ? 'second' : 'next'} page'),
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
                  LocalinoProvider.instance.changeLocale(
                      LocalinoProvider.instance.locale == 'en_US'
                          ? 'cs_CZ'
                          : 'en_US');
                },
                child: Text('Locale: ${LocalinoProvider.instance.locale}'),
              ),
              ElevatedButton(
                onPressed: () => context
                    .routeOf<SecondPage>()
                    ?.openRoute(args: counter.value),
                child: Text('Open Next'),
              ),
              ElevatedButton(
                onPressed: () =>
                    context.routeOf<ThirdPage>()?.openRoute(args: counter),
                child: Text('Open Scope'),
              ),
              LoaderStepIndicator(),
              TextField(),
            ],
          ),
        ),
        floatingActionButton: ControlBuilder<int>(
          control: counter,
          builder: (_, value) {
            return FloatingActionButton(
              child: Text(
                '$value',
                style: secondPage ? theme.textTheme.titleMedium : null,
              ),
              onPressed: () => counter.increment(),
            );
          },
          noData: (_) => BackButton(),
        ),
      ),
    );
  }
}

class ThirdPage extends SingleControlWidget<Counter> with InitProvider {
  @override
  Widget build(CoreContext context, Counter control) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThirdScope(),
            ElevatedButton(
              onPressed: () => control.increment(),
              child: Text('+'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThirdScope extends BaseControlWidget with LazyProvider {
  @override
  void mountDependencies(CoreContext context) {
    context.registerDependency<Counter>(scope: true, stateNotifier: true);
  }

  @override
  Widget build(CoreContext context) {
    final counter = context.get<Counter>();

    return Text('Init With: $counter - (${counter?.value})');
  }
}
