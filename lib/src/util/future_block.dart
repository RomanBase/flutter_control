import 'dart:async';

import 'package:flutter_control/core.dart';

/// Works similarly to [Future.delayed(duration)], but completion callback can be postponed.
/// Can be re-triggered multiple times - only last call will be handled.
class FutureBlock {
  Timer _timer;
  VoidCallback _callback;

  /// Returns true if last delay is in progress.
  bool get isActive => _timer != null && _timer.isActive;

  FutureBlock();

  /// Starts delay for given [duration]. Given callback can be postponed or canceled.
  /// Can be called multiple times - only last call will be handled.
  void delayed(Duration duration, VoidCallback onDone) {
    cancel();

    if (onDone == null) {
      printDebug('FutureBlock: null callback - delay not started');
      return;
    }

    _callback = onDone;
    _timer = Timer(duration, () {
      onDone();
      cancel();
    });
  }

  /// Re-trigger current delay action and sets new [duration], but block is postponed only when current delay [isActive].
  /// Can be called multiple times - only last call will be handled.
  bool postpone(Duration duration) {
    if (isActive) {
      delayed(duration, _callback);
    }

    return isActive;
  }

  /// Cancels current delay action.
  void cancel() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    _callback = null;
  }

  static Future nextFrame(VoidCallback action) => Future.delayed(const Duration(), action);
}

class DelayBlock {
  int _millis;
  DateTime _start;

  DelayBlock(Duration duration, [bool startNow = true]) {
    _millis = duration.inMilliseconds;
    if (startNow) {
      start();
    }
  }

  void start() {
    _start = DateTime.now();
  }

  Future<void> finish() {
    final currentDelay = DateTime.now().difference(_start).inMilliseconds;
    final delay = _millis - currentDelay;

    if (delay > 0) {
      return Future.delayed(Duration(milliseconds: delay));
    }

    return Future(() {});
  }
}
