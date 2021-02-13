import 'package:flutter_control/core.dart';

class CurveRange extends Curve {
  final Curve curve;
  final double begin;
  final double end;

  const CurveRange({
    @required this.curve,
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
  double get _begin => this is CurveRange ? (this as CurveRange).begin : 0.0;

  double get _end => this is CurveRange ? (this as CurveRange).end : 1.0;

  Curve from(double begin) => inRange(begin, _end);

  Curve to(double end) => inRange(_begin, end);

  Curve inRange(double begin, double end) => CurveRange(
        curve: this,
        begin: begin,
        end: end,
      );
}
