import 'package:flutter_control/control.dart';
import 'package:localino_live/localino_live.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Control.initControl(
      debug: true,
      modules: [
        RoutingModule([]),
        LocalinoModule(LocalinoOptions(
          setup: LocalinoSetup(
            space: 'apino',
            project: 'control',
            locales: {'en_US': DateTime(2000)},
          ),
        )),
      ],
      initializers: {
        CounterControl: (_) => CounterControl(),
        ...LocalinoLive.initializers,
      },
    );

    Control.factory.onReady()?.then((value) {
      LocalinoProvider.remote.loadRemoteTranslations().then((value) => printDebug(value));
    });

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (settings) => ControlRouteTransition(
        settings: settings,
        builder: (_) => MyHomePage(title: 'Flutter Demo'),
        transition: CrossTransition.slide(
          begin: Offset(-0.25, 0),
          end: Offset(-0.25, 0),
        ).buildRoute(),
      ),
    );
  }
}

class CounterControl extends BaseControl with NotifierComponent {
  int counter = 0;

  void incrementCounter() {
    counter++;
    notify();
  }
}

class MyHomePage extends SingleControlWidget<CounterControl> with RouteControl {
  MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  void onInit(Map args) {
    super.onInit(args);

    registerStateNotifier(LocalinoProvider.instance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times: ',
            ),
            ControlBuilder<dynamic>(
                control: control,
                builder: (context, value) {
                  return Text(
                    '${control.counter}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                }),
            ElevatedButton(
              onPressed: () => openRoute(ControlRoute.build<MyHomePage>(builder: (_) => MyHomePage(title: 'Next Page'))
                  .viaTransition(CrossTransition.route(
                    background: CrossTransition.slide(
                      begin: Offset(-0.25, 0),
                      end: Offset(-0.25, 0),
                    ),
                    foreground: CrossTransition.slide(
                      begin: Offset(1.0, 0),
                      end: Offset(1.0, 0),
                    ),
                  ))
                  .init()),
              child: Text(localize('app_name')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => control.incrementCounter(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
