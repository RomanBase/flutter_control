import 'package:flutter_control/core.dart';

import 'dashboard_page.dart';
import 'firebase_control.dart';
import 'login_page.dart';

enum UserStatus {
  authorized,
  anonymous,
  none,
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      entries: {
        FirebaseControl: FirebaseControl(),
      },
      routes: [
        ControlRoute.build<DashboardPage>(builder: (_) => DashboardPage()),
        ControlRoute.build<LoginPage>(builder: (_) => LoginPage()),
      ],
      states: [
        AppState.init.build(
          (context) => InitLoader.of(
            delay: const Duration(seconds: 1), //minimal duration of loading page
            builder: (context) => LoadingPage(),
            load: (_) async {
              if (await Control.get<FirebaseControl>().restoreUser() != null) {
                return UserStatus.authorized;
              }

              return UserStatus.none;
            },
          ),
        ),
        AppState.main.build((context) => MainPage()),
      ],
      app: (setup, home) => MaterialApp(
        key: setup.key,
        home: home,
        title: 'Login - Flutter Control',
      ),
    );
  }
}

class MainPage extends ControlWidget {
  UserStatus get status => getArg<UserStatus>();

  @override
  Widget build(BuildContext context) {
    if (status == UserStatus.none) {
      return LoginPage();
    }

    return DashboardPage();
  }
}

class LoadingPage extends SingleControlWidget<InitLoaderControl> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: LoadingBuilder(
        control: control.loading,
        progress: (_) => Center(
          child: SizedBox(
            width: 256.0,
            height: 256.0,
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_) => Center(
          child: Column(
            children: <Widget>[
              Text('something went wrong'),
              RaisedButton(
                onPressed: () => control.executeLoader(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
