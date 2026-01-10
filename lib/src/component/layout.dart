part of flutter_control;

/// A mixin for a [CoreWidget] that provides a callback after the first frame is rendered.
///
/// This is useful for performing actions that require the widget to be laid out
/// and have a size, such as showing an overlay or starting an animation.
mixin OnLayout on CoreWidget {
  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    WidgetsBinding.instance.addPostFrameCallback((_) => onLayout(context));
  }

  /// Called once after the first frame of the widget has been rendered.
  void onLayout(CoreContext context);
}
