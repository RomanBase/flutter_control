import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';
import 'package:testempty/empty_controllable.dart';
import 'package:testempty/empty_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This ui is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      theme: ThemeConfig(
        themes: {
          Brightness.light: (context) =>
              ThemeData.light().copyWith(primaryColor: Colors.blue),
          Brightness.dark: (context) =>
              ThemeData.dark().copyWith(primaryColor: Colors.orange),
        },
      ),
      initState: AppState.onboarding,
      states: [
        AppState.main.build((context) => MyHomePage(title: 'Example')),
        AppState.onboarding.build((context) => EmptyList()),
      ],
      app: (setup, home) => MaterialApp(
        key: setup.key,
        title: 'Empty',
        theme: setup.theme,
        home: home,
      ),
      initAsync: () async => await Future.delayed(Duration(seconds: 3)),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    printDebug('HOME PAGE BUILD');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: () {
              final theme = ThemeProvider.of(context);

              theme.changeTheme(
                  theme.config.getPreferredKey<Brightness>(Brightness.values) ==
                          Brightness.light
                      ? Brightness.dark
                      : Brightness.light);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
