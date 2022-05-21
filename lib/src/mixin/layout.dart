part of flutter_control;

mixin OnLayout on CoreWidget {
  @override
  void onInit(Map args) {
    super.onInit(args);

    WidgetsBinding.instance.addPostFrameCallback((_) => onLayout());
  }

  void onLayout();
}
