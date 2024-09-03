part of flutter_control;

class Device {
  final MediaQueryData data;

  const Device(this.data);

  factory Device.of(BuildContext context) => Device(MediaQuery.of(context));

  Brightness get brightness => data.platformBrightness;

  bool get portrait => data.orientation == Orientation.portrait;

  bool get landscape => data.orientation == Orientation.landscape;

  Size get size => data.size;

  double get width => size.width;

  double get height => size.height;

  double get ratio => 1.0 / data.devicePixelRatio;

  double get revertedRatio => 1.0 - ratio;

  double get screenRatio => width / height;

  double get landscapeScreenRatio => height / width;

  double get min => math.min(width, height);

  double get max => math.max(width, height);

  double get topBorderSize => data.padding.top;

  double get bottomBorderSize => data.padding.bottom;

  /// Converts px to logical display points
  /// PX -> DP
  double toDp(double value) => value * ratio;

  /// Converts logical display points to px
  /// DP -> PX
  double toPx(double value) => value / ratio;

  Size toDpSize(Size size) => Size(toDp(size.width), toDp(size.height));

  Size toPxSize(Size size) => Size(toPx(size.width), toPx(size.height));

  Offset toDpOffset(Offset offset) => Offset(toDp(offset.dx), toDp(offset.dy));

  Offset toPxOffset(Offset offset) => Offset(toPx(offset.dx), toPx(offset.dy));

  T onOrientation<T>(
      {InitFactory<T>? portrait, InitFactory<T>? landscape, dynamic args}) {
    if (this.portrait) {
      return portrait!(args);
    }

    return landscape!(args);
  }

  static T? onPlatform<T>({
    T Function()? android,
    T Function()? ios,
    T Function()? web,
    T Function()? desktop,
    T Function()? other,
  }) {
    if (kIsWeb) {
      return (web ?? other)?.call();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return (android ?? other)?.call();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (ios ?? other)?.call();
    }

    return (desktop ?? other)?.call();
  }
}
