import 'package:flutter_control/core.dart';

class CallbackHandler implements Disposable {
  VoidCallback _callback;

  bool get isValid => _callback != null;

  CallbackHandler({VoidCallback callback}) {
    _callback = callback;
  }

  void setCallback(VoidCallback callback) {
    _callback = callback;
  }

  void callback() {
    if (isValid) {
      _callback();
    }
  }

  @override
  void dispose() {
    _callback = null;
  }
}
