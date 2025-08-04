part of flutter_control;

class ContinuousCurve extends Curve {
  final List<Curve> curves;

  const ContinuousCurve({required this.curves});

  @override
  double transform(double t) {
    if (t == 0.0) {
      return curves.first.transform(0.0);
    }

    if (t == 1.0) {
      return curves.last.transform(1.0);
    }

    return transformInternal(t);
  }

  @override
  double transformInternal(double t) {
    final slice = 1.0 / curves.length;
    final index = (t / slice).floor();

    t = (t - (slice * index)) / slice;

    return curves[index].transform(t);
  }
}

class ReverseCurve extends Curve {
  final Curve curve;

  const ReverseCurve({required this.curve});

  @override
  double transform(double t) {
    return curve.transform(1.0 - t);
  }
}

extension ContinuousCurveExt on Curve {
  Curve get reversed => ReverseCurve(curve: this);

  Curve join(Curve other) {
    final curves = <Curve>[];

    if (this is ContinuousCurve) {
      curves.addAll(curves);
    } else {
      curves.add(this);
    }

    if (other is ContinuousCurve) {
      curves.addAll(other.curves);
    } else {
      curves.add(other);
    }

    return ContinuousCurve(curves: curves);
  }
}
