part of flutter_control;

mixin OnLayout on CoreWidget {
  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    WidgetsBinding.instance.addPostFrameCallback((_) => onLayout(context));
  }

  void onLayout(CoreContext context);
}
