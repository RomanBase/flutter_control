import 'dart:math' as math;

import 'package:flutter_control/core.dart';

class Device {
  final MediaQueryData data;

  const Device(this.data);

  factory Device.of(BuildContext context) => Device(MediaQuery.of(context));

  bool get portrait => data.orientation == Orientation.portrait;

  bool get landscape => data.orientation == Orientation.landscape;

  Size get size => data.size;

  double get width => size.width;

  double get height => size.height;

  double get ratio => 1.0 / data.devicePixelRatio;

  double get revertRatio => 1.0 - ratio;

  double get screenRatio => width / height;

  double get landscapeScreenRatio => height / width;

  double get min => math.min(width, height);

  double get max => math.max(width, height);

  @deprecated
  bool get hasNotch => data.padding.top > 20.0;

  double get topBorderSize => data.padding.top;

  double get bottomBorderSize => data.padding.bottom;

  /// Converts px to logical display points
  /// PX -> DP
  double px(double value) => value * ratio;

  /// Converts logical display points to px
  /// DP -> PX
  double dp(double value) => value / ratio;

  Size pxSize(Size size) => Size(px(size.width), px(size.height));

  Size dpSize(Size size) => Size(dp(size.width), dp(size.height));

  Offset pxOffset(Offset offset) => Offset(px(offset.dx), px(offset.dy));

  Offset dpOffset(Offset offset) => Offset(dp(offset.dx), dp(offset.dy));

  T onOrientation<T>(
      {Initializer<T>? portrait, Initializer<T>? landscape, dynamic args}) {
    if (this.portrait) {
      return portrait!(args);
    }

    return landscape!(args);
  }
}
