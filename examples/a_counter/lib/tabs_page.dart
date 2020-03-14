import 'package:flutter_control/core.dart';

import 'menu_page.dart';

class TabsPage extends BaseControlWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: RaisedButton(
        child: Text('toggle tabs'),
        onPressed: () {
          ControlProvider.get<CustomNavigatorStackController>().toggle();
        },
      ),
    ));
  }
}
