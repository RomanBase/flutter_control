import 'package:flutter_control/core.dart';

class Device {
  final MediaQueryData data;

  Device(this.data);

  factory Device.of(BuildContext context) => Device(MediaQuery.of(context));

  Size get size => data.size;

  double get width => size.width;

  double get height => size.height;

  double get ratio => 1.0 / data.devicePixelRatio;

  double px(double value) => value * ratio;

  double dp(double value) => value / ratio;

  bool get hasNotch => data.padding.top > 0.0;
}
