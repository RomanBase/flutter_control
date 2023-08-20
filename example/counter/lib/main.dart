import 'package:flutter_control/control.dart';
import 'package:localino_live/localino_live.dart';

void main() {
  runApp(const MyApp());

  final g1 = Generic();
  final g2 = Generic((value) {});

  print('${g1.generic} x ${g2.generic}');
}

class Generic<T> {
  final Function(T)? callback;

  const Generic([this.callback]);

  Type get generic => T;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      localization: LocalinoLive.options(
        remoteSync: true,
      ),
      initializers: {
        CounterControl: (_) => CounterControl(),
      },
      states: [
        AppState.init
            .build((context) => InitLoader.of(builder: (_) => Container())),
        AppState.main.build((context) => MyHomePage(title: 'Flutter Demo')),
      ],
      app: (setup, home) => MaterialApp(
        title: 'Flutter Demo',
        home: home,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        supportedLocales: setup.supportedLocales,
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
              LocalinoProvider.instance.localize('action_add'),
            ),
            Text(
              'You have pushed the button this many times: ',
            ),
            ControlBuilder(
              control: control,
              builder: (context, value) => Text(
                '${control.counter}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              noData: (_) => Text(
                'N${control.counter}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
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
