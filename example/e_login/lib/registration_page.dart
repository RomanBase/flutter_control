import 'package:flutter_control/core.dart';

import 'dashboard_page.dart';
import 'firebase_control.dart';

class RegistrationControl extends BaseControl with RouteControlProvider {
  final loading = LoadingControl();
  final username = InputControl(regex: '.{1,}@.{1,}\..{1,}'); // lame email check :)
  final nickname = InputControl(regex: '.{3,}');
  final password = InputControl(regex: '.{8,}');

  final message = StringControl();

  FirebaseControl get firebase => Control.get<FirebaseControl>();

  @override
  void onInit(Map args) {
    super.onInit(args);

    username.next(nickname).next(password).done(submit);
  }

  void submit() {
    message.value = null;

    if (!username.validateChain()) {
      if (!username.isValid) {
        username.setError('invalid e-mail address');
      }

      if (!nickname.isValid) {
        nickname.setError('at least 3 letters');
      }

      if (!password.isValid) {
        password.setError('at least 8 letters');
      }

      return;
    }

    loading.progress();

    firebase.register(username.value, password.value, nickname.value).then((value) {
      routeOf<DashboardPage>().openRoot(args: value);
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
    nickname.dispose();
    message.dispose();
  }
}

class RegistrationPage extends SingleControlWidget<RegistrationControl> with RouteControl, ThemeProvider {
  @override
  RegistrationControl initControl() => RegistrationControl();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              height: device.height,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64.0),
                    child: Text(
                      'New User',
                      style: font.headline2,
                    ),
                  ),
                  InputField(
                    control: control.username,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    hint: 'e-mail',
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  InputField(
                    control: control.nickname,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    hint: 'nickname',
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  InputField(
                    control: control.password,
                    textInputAction: TextInputAction.done,
                    hint: 'passowrd',
                    obscureText: true,
                  ),
                  SizedBox(
                    height: 32.0,
                  ),
                  LoadingBuilder(
                    control: control.loading,
                    done: (_) => RaisedButton(
                      onPressed: control.submit,
                      child: Text('create account'),
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
                ],
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: close,
            ),
          ),
        ],
      ),
    );
  }
}
