import 'package:flutter_control/core.dart';

mixin ControlsComponent on CoreWidget {
  Initializer get initComponents;

  Map get component => holder.args;

  @override
  void onInit(Map args) {
    super.onInit(args);

    dynamic components = initComponents.call(args);

    if (!(components is Map)) {
      components =
          Parse.toKeyMap(components, (key, value) => value.runtimeType);
    }

    holder.argStore.set(components);

    components.forEach((key, control) {
      if (control is Disposable) {
        register(control);
      }

      if (control is Initializable) {
        control.init(holder.args);
      }

      if (control is TickerComponent && this is TickerProvider) {
        control.provideTicker(this as TickerProvider);
      }
    });
  }
}
