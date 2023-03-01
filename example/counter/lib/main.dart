import 'package:flutter_control/control.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Control.initControl(initializers: {
      CounterControl: (_) => CounterControl(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
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
              child: Text('open next'),
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
