import 'package:flutter_control/core.dart';

class CrossControl extends ControlModel {
  final cross = ActionControl.single<String>('red');
}

class CrossPage extends SingleControlWidget<CrossControl> {
  @override
  Widget build(BuildContext context) {
    return ActionBuilder<String>(
      control: control.cross,
      builder: (context, value) {
        return CaseWidget(
          activeCase: value,
          builders: {
            'blue': (_) => Container(
                  color: Colors.blue,
                  child: Center(
                    child: RaisedButton(
                      onPressed: () => control.cross.value = 'red',
                      child: Text('cross to red'),
                    ),
                  ),
                ),
            'red': (_) => Container(
                  color: Colors.red,
                  child: Center(
                    child: RaisedButton(
                      onPressed: () => control.cross.value = 'orange',
                      child: Text('cross to orange'),
                    ),
                  ),
                ),
            'orange': (_) => Container(
                  color: Colors.orange,
                  child: Center(
                    child: RaisedButton(
                      onPressed: () => control.cross.value = 'none',
                      child: Text('cross to placeholder'),
                    ),
                  ),
                ),
          },
          placeholder: Container(
            color: Colors.grey,
            child: Center(
              child: RaisedButton(
                onPressed: () => control.cross.value = 'blue',
                child: Text('cross to blue'),
              ),
            ),
          ),
        );
      },
    );
  }
}
