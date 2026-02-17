part of flutter_control;

/// A curve that maps another curve to a specific interval of the 0.0-1.0 timeline.
class IntervalCurve extends Curve {
  /// The base curve to remap.
  final Curve curve;

  /// The start of the interval.
  final double begin;

  /// The end of the interval.
  final double end;

  /// Returns a new [IntervalCurve] with the interval reversed.
  IntervalCurve get reversed =>
      IntervalCurve(curve, begin: 1.0 - end, end: 1.0 - begin);

  /// Creates an interval curve.
  const IntervalCurve(
    this.curve, {
    this.begin = 0.0,
    this.end = 1.0,
  });

  @override
  double transformInternal(double t) {
    if (t < begin) {
      return curve.transform(0.0);
    }

    if (t > end) {
      return curve.transform(1.0);
    }

    final length = end - begin;
    t -= begin;

    return curve.transform(t / length);
  }
}

/// Extension on [Curve] to provide convenience methods for creating [IntervalCurve]s.
extension CurveEx on Curve {
  double get _begin =>
      this is IntervalCurve ? (this as IntervalCurve).begin : 0.0;

  double get _end => this is IntervalCurve ? (this as IntervalCurve).end : 1.0;

  /// Creates a new [IntervalCurve] from the current curve, starting at [begin].
  IntervalCurve from(double begin) => inRange(begin, _end);

  /// Creates a new [IntervalCurve] from the current curve, ending at [end].
  IntervalCurve to(double end) => inRange(_begin, end);

  /// Creates a new [IntervalCurve] from the current curve within the specified range.
  IntervalCurve inRange(double begin, double end) => IntervalCurve(
        this,
        begin: begin,
        end: end,
      );
}
