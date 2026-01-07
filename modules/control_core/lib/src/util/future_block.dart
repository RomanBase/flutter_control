part of '../../core.dart';

/// Whole class that serves as [Future.delayed].
class FutureBlock {
  /// Timer for delayed future.
  Timer? _timer;

  /// Callback of this delayed future.
  VoidCallback? _callback;

  /// Current delay duration.
  Duration? _duration;

  /// Returns true if last delay is in progress.
  bool get isActive => _timer != null && _timer!.isActive;

  /// Returns true if callback and duration is set.
  bool get isSet => _callback != null && _duration != null;

  /// Re-triggerable, re-usable delayed Future.
  /// This is just empty constructor.
  /// Use [delayed] to start timer.
  FutureBlock();

  /// Starts delay for given [duration]. Given callback can be postponed or canceled.
  /// If timer is active, then new delay is triggered and [duration] is restarted.
  void delayed(Duration duration, VoidCallback onDone) {
    cancel();

    _callback = onDone;
    _timer = Timer(_duration = duration, trigger);
  }

  /// Re-trigger current delay action and sets new [duration], but block is postponed only when current delay [isActive].
  /// Can be called multiple times - only last call will be handled.
  /// returns `true` if action is delayed.
  bool postpone(
      {Duration? duration, VoidCallback? onDone, bool retrigger = true}) {
    if (onDone != null) {
      _callback = onDone;
    }

    if (duration != null) {
      _duration = duration;
    }

    if (isActive || retrigger) {
      if (_duration == null || _callback == null) {
        printDebug(
            'Invalid FutureBlock - provider both [duration] and [onDone].');
        return false;
      }

      delayed(_duration!, _callback!);
    }

    return isActive;
  }

  /// Triggers current callback early.
  void trigger() {
    _callback?.call();
    stop();
  }

  /// Stops current timer.
  void stop() {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
    }

    _timer = null;
  }

  /// Stops current timer and cancels delayed action.
  void cancel() {
    stop();

    _callback = null;
  }

  /// Extends or Creates new [FutureBlock].
  factory FutureBlock.extend(
      {FutureBlock? parent,
      Duration? duration,
      VoidCallback? onDone,
      bool retrigger = true}) {
    final block = FutureBlock();
    block._duration = duration ?? parent?._duration;
    block._callback = onDone ?? parent?._callback;

    block.postpone(retrigger: (parent?.isActive ?? false) || retrigger);

    parent?.cancel();

    return block;
  }

  /// Runs delayed [onDone] callback.
  /// Returns new [FutureBlock] to control actions.
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

  /// Sequential wait.
  /// When [continuous] set and returns `false` then sequence is terminated.
  /// Returns list of results.
  static Future<List<T>> sequence<T>(Iterable<ValueGetter<Future<T>>> futures,
      {bool Function(T value)? continuous}) async {
    final results = <T>[];

    for (final future in futures) {
      results.add(await future());

      if (continuous != null && !continuous(results.last)) {
        break;
      }
    }

    return results;
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
