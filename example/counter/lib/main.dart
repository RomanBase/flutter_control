import 'package:flutter/cupertino.dart';
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

class UITheme extends ControlTheme {
  UITheme(super.context);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      /*localization: LocalinoLive.options(
        remoteSync: false,
      ),*/
      entries: {
        CounterControl: CounterControl(),
      },
      theme: ThemeConfig<UITheme>(
        builder: (context) => UITheme(context as BuildContext),
        themes: {
          Brightness.light: (theme) => ThemeData(primarySwatch: Colors.blue),
          Brightness.dark: (theme) => ThemeData(primarySwatch: Colors.orange),
        },
      ),
      states: [
        AppState.init
            .build((context) => InitLoader.of(builder: (_) => Container())),
        AppState.main.build((context) => MenuPage()),
      ],
      app: (setup, home) => MaterialApp(
        title: 'Flutter Demo',
        home: home,
        theme: setup.theme,
        //supportedLocales: setup.supportedLocales,
      ),
    );
  }
}

class CounterControl extends BaseControl with NotifierComponent {
  final counter2 = ActionControl.empty<int>();

  int counter = 0;

  void incrementCounter() {
    counter++;
    counter2.value = counter;
    notify();
  }
}

final nav = NavigatorStackControl();
int count = 2;

class MenuPage extends ControlWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: NavigatorStack.menu(
              control: nav,
              items: {
                ...Parse.toKeyMap(
                  List.generate(count, (index) => NavItem(key: index)),
                  (key, value) => value,
                  converter: (value) =>
                      (_) => MyHomePage(title: 'Flutter Demo ${value.key}'),
                ),
              },
            ),
          ),
          Row(
            children: [
              ...List.generate(
                count,
                (e) => Expanded(
                  child: CupertinoButton(
                    onPressed: () => nav.setPageIndex(e),
                    child: Text(e.toString()),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(bottom: 32.0),
            child: ElevatedButton(
              onPressed: () {
                nav.clear();
                count++;
                notifyState();
              },
              child: Text('add page'),
            ),
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends SingleControlWidget<CounterControl>
    with RouteControl, ThemeProvider {
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
              'You have pushed the button this many times: ',
            ),
            CaseWidget(
              activeCase:
                  'light', //PrefsProvider.instance.get(ThemeConfig.preference_key),
              builders: {
                'light': (_) => Container(
                      color: theme.primaryColor,
                      child: Text('light'),
                    ),
                'dark': (_) => Container(
                      color: theme.primaryColor,
                      child: Text('dark'),
                    ),
              },
              placeholder: (_) => Text('default'),
            ),
            Container(
              color: theme.primaryColor,
              child: ControlBuilder(
                control: control,
                builder: (context, value) => Text(
                  '${control.counter}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ControlBuilder<int>(
                  control: control.counter2,
                  builder: (context, value) => Container(
                    color: theme.primaryColor,
                    child: Text(
                      '$value',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  noData: (_) => Text(
                    '---',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SizedBox(
                  width: 32.0,
                ),
                ControlBuilder(
                  control: control.counter2,
                  builder: (context, value) => Container(
                    color: theme.primaryColor,
                    child: Text(
                      value is int ? '$value' : '---',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32.0,
                ),
                ControlBuilder<dynamic>(
                  control: control.counter2,
                  builder: (context, value) => Container(
                    color: theme.primaryColor,
                    child: Text(
                      value is int ? '$value' : '---',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32.0,
                ),
                ControlBuilder<CounterControl>(
                  control: control,
                  builder: (context, value) => Container(
                    color: theme.primaryColor,
                    child: Text(
                      value.counter > 0 ? '${value.counter}' : '---',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          control.incrementCounter();
          theme.changeTheme(
              PrefsProvider.instance.get(ThemeConfig.preference_key) == 'light'
                  ? Brightness.dark
                  : Brightness.light);
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
