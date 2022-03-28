import 'package:flutter_control/core.dart';

final action = ActionControl.broadcast(-1);
final model = EmptyModel();

int count = 0;

class EmptyControllableWidget extends ControlWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusWidget(action),
            StatusWidget(model),
          ],
        ),
      ),
    );
  }
}

class EmptyModel extends BaseModel with ObservableComponent {}

class StatusWidget extends ControllableWidget with CoreWidgetDebugPrinter {
  StatusWidget(control) : super(control);

  @override
  Widget build(BuildContext context) {
    control.value = UnitId.nextId();

    Future.delayed(Duration(milliseconds: 5000), () {
      control.value = UnitId.nextId();
    });

    count++;

    return Text(
      'Current status $count: $value ${value == control.value}',
    );
  }
}
