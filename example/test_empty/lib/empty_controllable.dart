import 'package:flutter_control/core.dart';

class EmptyControllableWidget extends ControlWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StatusWidget(ActionControl.broadcast()),
      ),
    );
  }
}

class StatusWidget extends ControllableWidget with CoreWidgetDebugPrinter {
  StatusWidget(control) : super(control);

  @override
  Widget build(BuildContext context) {
    return Text(
      'Current status: $value',
    );
  }
}
