part of flutter_control;

/// Extension on [BuildContext] to provide convenient access to view and media query information.
extension MediaViewExt on BuildContext {
  /// The [FlutterView] for this context.
  FlutterView get view => View.of(this);

  /// The [MediaQueryData] for this context, derived from the view.
  MediaQueryData get media => MediaQueryData.fromView(view);
}

/// Extension on [FlutterView] to provide view size information.
extension FlutterViewExt on FlutterView {
  /// The logical size of the view (in logical pixels).
  Size get viewSize => physicalSize / devicePixelRatio;
}

/// Extension on [Display] to provide view size information.
extension DisplayExt on Display {
  /// The logical size of the display (in logical pixels).
  Size get viewSize => size / devicePixelRatio;
}
