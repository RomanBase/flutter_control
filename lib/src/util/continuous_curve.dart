part of flutter_control;

/// A [Curve] that combines multiple curves into a single continuous curve.
/// Each curve is given an equal portion of the timeline.
class ContinuousCurve extends Curve {
  /// The list of curves to combine.
  final List<Curve> curves;

  /// Creates a continuous curve from a list of curves.
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

/// A curve that reverses the output of another curve.
class ReverseCurve extends Curve {
  /// The curve to reverse.
  final Curve curve;

  /// Creates a reverse curve.
  const ReverseCurve({required this.curve});

  @override
  double transform(double t) {
    return curve.transform(1.0 - t);
  }
}

/// Extension on [Curve] to provide convenience methods for combining and reversing curves.
extension ContinuousCurveExt on Curve {
  /// Returns a [ReverseCurve] that is the reverse of this curve.
  Curve get reversed => ReverseCurve(curve: this);

  /// Joins this curve with another curve to create a [ContinuousCurve].
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
