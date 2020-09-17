import 'package:flutter_control/core.dart';

import 'firebase_control.dart';
import 'registration_page.dart';

class LoginControl extends BaseControl with RouteControlProvider {
  final loading = LoadingControl();
  final username = InputControl(regex: '.{1,}@.{1,}\..{1,}'); // lame email check :)
  final password = InputControl(regex: '.{8,}');

  final message = StringControl();

  FirebaseControl get firebase => Control.get<FirebaseControl>();

  @override
  void onInit(Map args) {
    super.onInit(args);

    username.next(password).done(submit);
  }

  void submit() {
    message.value = null;

    if (!username.validateChain()) {
      if (!username.isValid) {
        username.error = 'invalid e-mail address';
      }

      if (!password.isValid) {
        password.error = 'at least 8 letters';
      }

      return;
    }

    loading.progress();

    firebase.login(username.text, password.text).then((value) {
      Control.scope.setMainState(args: value);
    }).catchError((err) {
      message.setValue(err.message);
      loading.done();
    });
  }

  @override
  void dispose() {
    super.dispose();

    loading.dispose();
    username.dispose();
    password.dispose();
    message.dispose();
  }
}

class LoginPage extends SingleControlWidget<LoginControl> with RouteControl, ThemeProvider {
  @override
  LoginControl initControl() => LoginControl();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: device.height,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64.0),
                child: Text(
                  'Welcome',
                  style: font.headline3,
                ),
              ),
              InputFieldV1(
                control: control.username,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                hint: 'e-mail',
              ),
              Stack(
                children: <Widget>[
                  InputFieldV1(
                    control: control.password,
                    textInputAction: TextInputAction.done,
                    hint: 'passowrd',
                    obscureText: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.visibility),
                      onPressed: () => control.password.obscure = !control.password.obscure,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16.0,
              ),
              LoadingBuilder(
                control: control.loading,
                done: (_) => RaisedButton(
                  onPressed: control.submit,
                  child: Text('sign in'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: FieldBuilder(
                  control: control.message,
                  builder: (context, value) => Text(
                    value,
                    style: font.bodyText2.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              FlatButton(
                onPressed: () {
                  control.username.unfocusChain();
                  ControlRoute.build(identifier: '/registration', builder: (_) => RegistrationPage()).navigator(this).openRoute();
                },
                child: Text(
                  'Don\'t have account? Sign Up!',
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
