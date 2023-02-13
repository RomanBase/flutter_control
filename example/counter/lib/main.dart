import 'package:flutter_control/control.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Control.initControl();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        model: TextModel(),
      ),
    );
  }
}

class TextModel extends BaseModel with NotifierComponent {
  int counter = 0;

  void incrementCounter() {
    counter++;
    notify();
  }
}

class MyHomePage extends BaseControlWidget {
  MyHomePage({
    super.key,
    required this.title,
    required this.model,
  });

  final String title;
  final TextModel model;

  @override
  void onInit(Map args) {
    super.onInit(args);

    registerStateNotifier(model);
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${model.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => model.incrementCounter(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
