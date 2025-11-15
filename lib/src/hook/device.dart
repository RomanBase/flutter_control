part of flutter_control;

extension MediaViewExt on BuildContext {
  FlutterView get view => View.of(this);

  MediaQueryData get media => MediaQueryData.fromView(view);
}

extension FlutterViewExt on FlutterView {
  Size get viewSize => physicalSize / devicePixelRatio;
}

extension DisplayExt on Display {
  Size get viewSize => size / devicePixelRatio;
}
