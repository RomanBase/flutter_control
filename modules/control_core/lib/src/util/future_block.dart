part of '../../core.dart';

/// A utility class for creating a re-triggerable, cancellable delayed future.
///
/// This is useful for debouncing actions, such as waiting for a user to stop
/// typing before performing a search.
///
/// Example:
/// ```dart
/// final searchDebouncer = FutureBlock();
///
/// void onSearchQueryChanged(String query) {
///   searchDebouncer.delayed(Duration(milliseconds: 500), () {
///     print('Performing search for: $query');
///   });
/// }
/// ```
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

  /// Starts or restarts the timer for a given [duration].
  ///
  /// When the timer completes, [onDone] is executed. If `delayed` is called again
  /// while a timer is active, the previous timer is canceled and a new one starts.
  void delayed(Duration duration, VoidCallback onDone) {
    cancel();

    _callback = onDone;
    _timer = Timer(_duration = duration, trigger);
  }

  /// Postpones the currently scheduled action.
  ///
  /// If a timer is active, it will be reset with the new (or existing) duration.
  /// If `retrigger` is true and no timer is active, a new one will be started.
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

  /// Immediately executes the scheduled callback and stops the timer.
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

  /// Cancels the scheduled action and stops the timer.
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

  /// A utility equivalent to `Future.wait`, but it safely handles `null` futures in the list.
  static Future wait(Iterable<Future?> futures) async {
    final futuresToWait = futures.where((item) => item != null).cast<Future>();

    if (futuresToWait.isNotEmpty) {
      await Future.wait(futuresToWait);
    }
  }

  /// Executes a sequence of future-producing functions one after another.
  ///
  /// - [continuous]: An optional callback that can stop the sequence early if it returns `false`.
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

/// A helper to ensure a block of asynchronous code takes a minimum amount of time to complete.
///
/// This is useful for preventing jarring UI flashes when an operation finishes
/// too quickly (e.g., a loading indicator that appears and disappears instantly).
///
/// Example:
/// ```dart
/// final delay = DelayBlock(Duration(milliseconds: 500));
/// await veryFastApiCall();
/// await delay.finish(); // This will wait for the remaining time.
/// ```
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

  /// Starts the timer. This should be called before the async operation begins.
  void start() {
    _start = DateTime.now();
  }

  /// Awaits the completion of the delay block.
  ///
  /// If the time elapsed since [start] was called is less than the specified
  /// duration, this will await the remaining time. Otherwise, it completes immediately.
  Future<void> finish() {
    final currentDelay = DateTime.now().difference(_start).inMilliseconds;
    final delay = _millis - currentDelay;

    if (delay > 0) {
      return Future.delayed(Duration(milliseconds: delay));
    }

    return Future(() {});
  }
}
