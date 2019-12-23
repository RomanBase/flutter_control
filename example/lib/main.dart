import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';

import 'cards_controller.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget with LocalizationProvider, PrefsProvider {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlBase(
      debug: true,
      defaultLocale: 'en',
      locales: {
        'en': AssetPath().localization('en'),
        'cs': 'assets/localization/cs.json',
      },
      entries: {
        'cards': CardsController(),
        CounterController: CounterController(),
      },
      initializers: {
        DetailController: (args) => DetailController(),
        CounterModel: (args) => CounterModel(),
      },
      injector: Injector.of({
        ControlTheme: (item, args) => item.asset = AssetPath(rootDir: 'assets'),
      }),
      theme: (context) => MyTheme(context),
      root: (context) => CounterPage(),
      app: (context, key, home) {
        return BroadcastBuilder<ThemeData>(
            key: 'theme',
            defaultValue: ThemeData(
              primaryColor: Colors.orange,
            ),
            builder: (context, theme) {
              return MaterialApp(
                key: key,
                home: home,
                title: localizeDynamic('app_name', defaultValue: 'Flutter Example') as String,
                theme: theme,
              );
            });
      },
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
}

class CounterModel extends BaseModel with StateController {
  int count;

  @override
  void init(Map args) {
    count = args.getArg<int>(defaultValue: -1);
  }

  void increase() {
    count++;
    notifyState();
  }
}

class CounterItem extends SingleControlWidget<CounterModel> {
  CounterItem({Key key, int defaultValue: 10}) : super(key: key, args: defaultValue);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(controller.count.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increase,
        child: Text('+'),
      ),
    );
  }
}

class CounterController extends BaseController {
  final count = IntegerControl();

  void increase() => count.value++;

  @override
  void dispose() {
    super.dispose();
    count.dispose();
  }
}

class CounterPage extends SingleControlWidget<CounterController> {
  CounterPage({Key key, CounterController controller, int defaultValue: 10}) : super(key: key, args: [controller, defaultValue]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FieldBuilder<int>(
            controller: controller.count,
            builder: (context, value) {
              return Text(value.toString());
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increase,
        child: Text('+'),
      ),
    );
  }
}

PageRouteProvider get counterPageRoute => PageRouteProvider.of(
  identifier: 'counter',
  builder: (context) => CounterPage(),
);

class HelloController extends BaseController with RouteController {

  void navigateNext() => openPage(counterPageRoute);
}
