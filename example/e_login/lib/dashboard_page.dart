import 'package:flutter_control/core.dart';

import 'firebase_control.dart';
import 'login_page.dart';

class DashboardPage extends BaseControlWidget with RouteControl, ThemeProvider {
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
                'Hello ${firebase.user.displayName}',
                style: font.display4,
                textAlign: TextAlign.center,
              ),
            ),
            RaisedButton(
              onPressed: () {
                firebase.logout();
                routeOf<LoginPage>().openRoot();
              },
              child: Text('logout'),
            ),
          ],
        ),
      ),
    );
  }
}
