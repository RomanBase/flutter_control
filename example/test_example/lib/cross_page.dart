import 'package:flutter_control/core.dart';

class CrossControl extends ControlModel with ReferenceCounter {
  final cross = ActionControl.single<String>('red');

  @override
  void dispose() {
    super.dispose();
    cross.dispose();

    printDebug('DISPOSE CROSS - no reference');
  }
}

class CrossPage extends SingleControlWidget<CrossControl> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ActionBuilder<String>(
            control: control.cross,
            builder: (context, value) {
              return CaseWidget(
                activeCase: value,
                args: control,
                builders: {
                  'blue': (_) => CrossControlPage('red', Colors.blue),
                  'red': (_) => CrossControlPage('orange', Colors.red),
                  'orange': (_) => CrossControlPage('placeholder', Colors.orange),
                },
                placeholder: CrossControlPage('blue', Colors.black),
                transition: CrossTransition(
                  duration: Duration(seconds: 3),
                  builder: CrossTransitions.fadeOutFadeIn(),
                ),
              );
            },
          ),
        ),
        RaisedButton(
          onPressed: notifyState,
          child: Text('notify state'),
        ),
        RaisedButton(
          onPressed: () => Control.root().setOnboardingState(),
          child: Text('reload app'),
        ),
      ],
    );
  }
}

class CrossControlPage extends SingleControlWidget<CrossControl> {
  final String next;
  final Color color;

  CrossControlPage(this.next, this.color) : super(key: ObjectKey(next));

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: RaisedButton(
          onPressed: () => control.cross.value = next,
          child: Text('cross to $next'),
        ),
      ),
    );
  }
}
