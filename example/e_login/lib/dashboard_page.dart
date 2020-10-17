import 'package:flutter_control/core.dart';

import 'firebase_control.dart';

class DashboardPage extends ControlWidget
    with RouteControl, ThemeProvider, TickerAnimControl<String> {
  FirebaseControl get firebase => Control.get<FirebaseControl>();

  AnimationController get helloAnim => anim['hello'];

  @override
  Map<String, Duration> get animations => {
        'hello': Duration(seconds: 1),
      };

  @override
  void onInit(Map args) {
    super.onInit(args);

    helloAnim.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Yay, you are logged in !',
              style: font.headline3,
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64.0),
              child: Text(
                'Hello ${firebase.username}',
                style: font.headline2,
                textAlign: TextAlign.center,
              ),
            ),
            AnimatedBuilder(
              animation: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: helloAnim, curve: Curves.ease)),
              builder: (context, child) => Container(
                width: 120.0 + device.width * 0.5 * helloAnim.value,
                child: RaisedButton(
                  onPressed: helloAnim.isAnimating
                      ? null
                      : () {
                          helloAnim.reverse().then((value) {
                            firebase.logout();
                            Control.scope.setAuthState();
                          });
                        },
                  child: Text('logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
