import 'package:flutter_control/core.dart';
import 'package:spends/control/account/account_control.dart';

class AccountPage extends SingleControlWidget<AccountControl> with RouteNavigator {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(child: Text('account')),
          RaisedButton(
            onPressed: control.signOut,
            child: Text('sign out'),
          ),
        ],
      ),
    );
  }
}
