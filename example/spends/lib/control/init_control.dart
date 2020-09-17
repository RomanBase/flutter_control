import 'dart:async';

import 'package:flutter_control/core.dart';
import 'package:spends/fire/fire_control.dart';

enum SignMode {
  sign_in,
  sign_up,
  sign_pass,
}

class InitControl extends InitLoaderControl with FireProvider {
  final Completer _onAuthorized = Completer();

  final username = InputControl(regex: '.{1,}@.{1,}\..{1,}');
  final password = InputControl(regex: '.{8,}');
  final nickname = InputControl(regex: '.{3,}');

  @override
  void onInit(Map args) {
    super.onInit(args);

    if (Control.debug) {
      username.text = 'test@test.test';
      password.text = '12345678';
    }
  }

  @override
  Future<dynamic> load() async {
    await fire.restore();

    // fire.isUserSignedIn is handled in _UIControl.
    loading.done();

    await _onAuthorized.future;
  }

  void signIn() async {
    loading.progress();

    await fire.signIn(username.text, password.text).then((user) {
      loading.done();
    }).catchError((err) {
      loading.error();
    });
  }

  void signUp() async {
    loading.progress();

    await fire.signUp(username.text, password.text, nickname.text).then((user) {
      loading.done();
    }).catchError((err) {
      loading.error();
    });
  }

  void resetPass() async {
    loading.progress();

    await fire.requestPasswordReset(username.text).then((_) {
      loading.done(msg: SignMode.sign_in);
    }).catchError((err) {
      loading.error();
    });
  }

  void complete() {
    if (!_onAuthorized.isCompleted) {
      _onAuthorized.complete();
    }
  }
}
