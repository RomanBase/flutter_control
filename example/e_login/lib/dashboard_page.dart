import 'package:flutter_control/core.dart';

import 'firebase_control.dart';

class DashboardPage extends ControlWidget with RouteControl, ThemeProvider {
  FirebaseControl get firebase => Control.get<FirebaseControl>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Yay, you are logged in !',
              style: font.display3,
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64.0),
              child: Text(
                'Hello ${firebase.username}',
                style: font.display4,
                textAlign: TextAlign.center,
              ),
            ),
            RaisedButton(
              onPressed: () {
                firebase.logout();
                Control.root().setAuthState();
              },
              child: Text('logout'),
            ),
          ],
        ),
      ),
    );
  }
}
