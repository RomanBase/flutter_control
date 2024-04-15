part of flutter_control;

mixin ContextComponent on ControlModel {
  CoreContext? context;

  @override
  void register(object) {
    super.register(object);

    if (object is CoreState) {
      context = object.element;
    }

    if (object is CoreContext) {
      context = object;
    }
  }
}
