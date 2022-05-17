import '../../core.dart';

abstract class ControlModule<T> implements Comparable<ControlModule> {
  Type get key => T;

  T? module;

  int priority = -1;

  Map get entries => {key: module};

  Map<dynamic, Initializer> get initializers => {};

  bool get preInit => priority > 0;

  bool get isInitialized => module != null;

  void initModule() {
    if (Control.isInitialized) {
      final object = Control.get<T>(key: key);

      if (object != null) {
        module = object;
      }
    }
  }

  Future? init();

  int compareTo(ControlModule other) {
    if (priority > other.priority) {
      return -1;
    } else if (priority < other.priority) {
      return 1;
    }

    return 0;
  }
}
