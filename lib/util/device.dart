import 'package:flutter_control/core.dart';

class Device {
  final MediaQueryData data;

  Device(this.data);

  factory Device.of(BuildContext context) => Device(MediaQuery.of(context));

  Size get size => data.size;

  double get width => size.width;

  double get height => size.height;

  double get ratio => 1.0 / data.devicePixelRatio;

  bool get hasNotch => data.padding.top > 20.0;

  double get topBorderSize => data.padding.top;

  double get bottomBorderSize => data.padding.bottom;

  double px(double value) => value * ratio;

  double dp(double value) => value / ratio;
}
