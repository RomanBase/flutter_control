part of '../../core.dart';

/// Whole class that serves as [Future.delayed].
class FutureBlock {
  /// Timer for delayed future.
  Timer? _timer;

  /// Callback of this delayed future.
  VoidCallback? _callback;

  /// Returns true if last delay is in progress.
  bool get isActive => _timer != null && _timer!.isActive;

  /// Re-triggerable, re-usable delayed Future.
  /// This is just empty constructor.
  /// Use [delayed] to start timer.
  FutureBlock();

  /// Starts delay for given [duration]. Given callback can be postponed or canceled.
  /// If timer is active, then new delay is triggered and [duration] is restarted.
  void delayed(Duration duration, VoidCallback onDone) {
    cancel();

    _callback = onDone;
    _timer = Timer(duration, () {
      onDone();
      cancel();
    });
  }

  /// Re-trigger current delay action and sets new [duration], but block is postponed only when current delay [isActive].
  /// Can be called multiple times - only last call will be handled.
  /// returns `true` if action is delayed.
  /// returns `false` when this future block is already finished. Re-trigger with [delayed].
  bool postpone(Duration duration) {
    if (isActive) {
      if (_callback == null) {
        printDebug('Invalid Callback');
        return false;
      }

      delayed(duration, _callback!);
    }

    return isActive;
  }

  /// Cancels current delayed action.
  void cancel() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    _callback = null;
  }

  static FutureBlock run(Duration duration, VoidCallback onDone) =>
      FutureBlock()..delayed(duration, onDone);

  /// Runs delayed [Future] with zero [Duration] so [action] should be performed next frame.
  static Future nextFrame(VoidCallback action) =>
      Future.delayed(const Duration(), action);

  /// Same as [Future.wait] but nullable.
  static Future wait(Iterable<Future?> futures) async {
    final futuresToWait = futures.where((item) => item != null).cast<Future>();

    if (futuresToWait.isNotEmpty) {
      await Future.wait(futuresToWait);
    }
  }
}

/// Helps to block part of code for minimum-given time.
/// Just wrap code with [start] and [finish].
/// If code runs fast, then finish is awaited for rest of [duration].
/// If code runs too slowly, then finish is triggered immediately.
class DelayBlock {
  /// Delay in milliseconds.
  late int _millis;

  /// Timestamp of block start.
  late DateTime _start;

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
