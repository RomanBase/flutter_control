import 'dart:async';

import 'package:flutter_control/core.dart';

/// Works similarly to [Future.delayed(duration)], but completion callback can be postponed.
/// Can be re-triggered multiple times - only last call will be handled.
class FutureBlock {
  Timer _timer;
  VoidCallback _callback;

  /// Returns true if last delay is in progress.
  bool get isActive => _timer != null && _timer.isActive;

  /// Default constructor.
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

  /// Runs delayed [Future] with zero [Duration] so [action] will be performed next frame.
  static Future nextFrame(VoidCallback action) =>
      Future.delayed(const Duration(), action);

  /// Same as [Future.wait] but nullable.
  static Future wait(Iterable<Future> futures) async {
    futures = futures.where((item) => item != null);

    if (futures.length > 0) {
      await Future.wait(futures);
    }
  }
}

/// Helps to block part of code for minimum-given time.
/// Just wrap code with [start] and [finish].
/// If code runs fast, then finish is awaited for rest of [duration].
/// If code runs too slowly, then finish is triggered immediately.
class DelayBlock {
  /// Delay in milliseconds.
  int _millis;

  /// Timestamp of block start.
  DateTime _start;

  /// Default constructor
  /// [duration] of delay block.
  /// [startNow] immediately in constructor.
  DelayBlock(Duration duration, [bool startNow = true]) {
    _millis = duration.inMilliseconds;
    if (startNow) {
      start();
    }
  }

  /// Sets start timestamp.
  /// Can be called multiple times - timestamp is updated and delay postponed.
  void start() {
    _start = DateTime.now();
  }

  /// awaits delay finish.
  /// If code runs fast, then finish is awaited for rest of [duration].
  /// If code runs too slowly, then finish is triggered immediately.
  Future<void> finish() {
    final currentDelay = DateTime.now().difference(_start).inMilliseconds;
    final delay = _millis - currentDelay;

    if (delay > 0) {
      return Future.delayed(Duration(milliseconds: delay));
    }

    return Future(() {});
  }
}
