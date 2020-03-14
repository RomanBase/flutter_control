import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

class NumberControl extends ControlModel with RouteControlProvider {
  final number = IntegerControl();
  bool closeable;

  Timer timer;

  @override
  void init(Map args) {
    number.value = args.getArg<int>(defaultValue: 999);
    closeable = args.getArg<bool>(defaultValue: false);

    startTimer();
  }

  startTimer() {
    stopTimer();

    timer = Timer.periodic(Duration(seconds: 1), (_) {
      number.value--;

      if (number.value <= 0) {
        close();
      }
    });
  }

  stopTimer() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }

  openNext() async {
    stopTimer();

    await routeOf<NumberPage>().path('/${number.value}').openRoute(args: [number.value, true]);

    startTimer();
  }

  @override
  void dispose() {
    number.dispose();
    stopTimer();
  }
}

class NumberPage extends SingleControlWidget<NumberControl> with RouteControl {
  @override
  NumberControl initControl() => NumberControl();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Number page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Number provided via args:',
              style: Theme.of(context).textTheme.title,
            ),
            SizedBox(
              height: 16.0,
            ),
            Text(
              getArg<int>(defaultValue: -1).toString(),
              style: Theme.of(context).textTheme.display2,
            ),
            SizedBox(
              height: 32.0,
            ),
            Text(
              'This page will close atomatically in:',
            ),
            FieldBuilder<int>(
              control: control.number,
              builder: (context, value) => Text(
                value.toString(),
                style: Theme.of(context).textTheme.title,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: RaisedButton(
                onPressed: () => control.openNext(),
                child: Text('open next'),
              ),
            ),
            if (control.closeable)
              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: RaisedButton(
                      onPressed: () => close(),
                      child: Text('close'),
                    ),
                  ),
                  RaisedButton(
                    onPressed: () => backToRoot(),
                    child: Text('close all'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
