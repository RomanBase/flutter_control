import 'package:flutter_control/core.dart';
import 'package:testempty/main.dart';

class EmptyControl extends ControlWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StatusWidget(ActionControl.broadcast(0)),
      ),
    );
  }
}
