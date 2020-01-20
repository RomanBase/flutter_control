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
      username.value = 'test@test.test';
      password.value = '12345678';
    }
  }

  @override
  Future<dynamic> load() async {
    await Control.factory().onReady();

    await fire.restore();

    Control.localization().loading.once((value) => loading.status(value), until: (value) => !value);

    await _onAuthorized.future;
  }

  void signIn() async {
    loading.progress();

    await fire.signIn(username.value, password.value).then((user) {
      loading.done();
    }).catchError((err) {
      loading.error();
    });
  }

  void signUp() async {
    loading.progress();

    await fire.signUp(username.value, password.value, nickname.value).then((user) {
      loading.done();
    }).catchError((err) {
      loading.error();
    });
  }

  void resetPass() async {
    loading.progress();

    await fire.requestPasswordReset(username.value).then((_) {
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
