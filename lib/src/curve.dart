part of flutter_control;

class IntervalCurve extends Curve {
  final Curve curve;
  final double begin;
  final double end;

  IntervalCurve get reversed =>
      IntervalCurve(curve, begin: 1.0 - end, end: 1.0 - begin);

  const IntervalCurve(
    this.curve, {
    this.begin: 0.0,
    this.end: 1.0,
  });

  @override
  double transformInternal(double t) {
    if (t < begin) {
      return 0.0;
    }

    if (t > end) {
      return 1.0;
    }

    final length = end - begin;
    t -= begin;

    return curve.transformInternal(t / length);
  }
}

extension CurveEx on Curve {
  double get _begin =>
      this is IntervalCurve ? (this as IntervalCurve).begin : 0.0;

  double get _end => this is IntervalCurve ? (this as IntervalCurve).end : 1.0;

  IntervalCurve from(double begin) => inRange(begin, _end);

  IntervalCurve to(double end) => inRange(_begin, end);

  IntervalCurve inRange(double begin, double end) => IntervalCurve(
        this,
        begin: begin,
        end: end,
      );
}
