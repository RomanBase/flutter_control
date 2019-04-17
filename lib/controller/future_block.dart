import 'dart:async';

import 'package:flutter_control/core.dart';

/// Works similarly to [Future.delayed(duration)], but completion callback can be postponed.
/// [delayed] can be called multiple times - only last call will be handled.
class FutureBlock {
  Timer _timer;
  VoidCallback _callback;

  bool get isActive => _timer != null && _timer.isActive;

  FutureBlock();

  /// re-trigger current delay action and sets new duration.
  /// can be called multiple times - only last call will be handled.
  void delayed(Duration duration, VoidCallback onDone) {
    cancel();

    _callback = onDone;
    _timer = Timer(duration, () {
      onDone();
      cancel();
    });
  }

  /// re-trigger current delay action and sets new duration, but block is postponed only when current delay is active.
  /// can be called multiple times - only last call will be handled.
  bool postpone(Duration duration) {
    if (isActive) {
      delayed(duration, _callback);
    }

    return isActive;
  }

  /// cancel current delay action.
  void cancel() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    _callback = null;
  }
}
