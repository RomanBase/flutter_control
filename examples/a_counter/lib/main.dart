import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      disableLoader: true,
      entries: {
        CounterControl: CounterControl(),
      },
      root: (_, __) => CounterPage(),
      app: (context, key, home) => MaterialApp(
        key: key,
        home: home,
        title: 'Counter - Flutter Control',
      ),
    );
  }
}

class CounterControl extends BaseControl {
  final counter = IntegerControl.inRange(value: 5, max: 10);
  final progress = DoubleControl();
  final message = StringControl("Press button to increase or decrese counter");

  @override
  void onInit(Map args) {
    super.onInit(args);

    counter.streamTo(progress, converter: (value) => value / counter.max);
  }

  void incrementCounter() {
    counter.value++;
    message.value = counter.atMax ? "Counter value at Maximum !" : "Counter value Increasing...";
  }

  void decrementCounter() {
    counter.value--;
    message.value = counter.atMin ? "Counter value at Minimum !" : "Counter value Decreasing...";
  }

  @override
  void dispose() {
    super.dispose();

    counter.dispose();
    progress.dispose();
  }
}

class CounterPage extends SingleControlWidget<CounterControl> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FieldBuilder<String>(
              control: control.message,
              builder: (context, value) {
                return Text(value);
              },
            ),
            SizedBox(
              height: 16.0,
            ),
            FieldBuilder<int>(
              control: control.counter,
              builder: (context, value) {
                return Text(
                  '$value',
                  style: Theme.of(context).textTheme.display1,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FieldBuilder<double>(
                control: control.progress,
                builder: (context, value) {
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: value),
                    duration: const Duration(milliseconds: 150),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () => control.decrementCounter(),
                ),
                SizedBox(
                  width: 16.0,
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => control.incrementCounter(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
