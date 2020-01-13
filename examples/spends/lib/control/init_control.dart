import 'dart:async';

import 'package:flutter_control/core.dart';
import 'package:spends/data/fire_control.dart';

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

    username.next(password).done(submit);
  }

  @override
  Future<dynamic> load() async {
    await Control.factory().onReady();

    await fire.restore();

    if (!fire.isUserSignedIn) {
      loading.done();
      await _onAuthorized.future;
    }
  }

  void submit() {
    if (username.validateChain()) {
      signIn();
    }
  }

  void signIn() async {
    loading.progress();

    await fire.signIn(username.value, password.value).then((user) {
      _onAuthorized.complete();
    });

    loading.done();
  }

  void signUp() async {
    loading.progress();

    await fire.signUp(username.value, password.value, nickname.value).then((user) {
      _onAuthorized.complete();
    });

    loading.done();
  }
}
