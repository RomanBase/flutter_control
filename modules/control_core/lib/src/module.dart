part of control_core;

abstract class ControlModule<T> implements Comparable<ControlModule> {
  Type get key => T;

  T? module;

  int priority = -1;

  Map get entries => {key: module};

  Map<Type, Initializer> get initializers => {};

  bool get preInit => priority > 0;

  bool get isInitialized => module != null;

  void initModule() {
    if (Control.isInitialized) {
      module = Control.get<T>(key: key);
    }
  }

  void initStore() {
    if (entries.isNotEmpty) {
      entries.forEach((key, value) {
        Control.set(key: key, value: value);
      });
    }

    if (initializers.isNotEmpty) {
      initializers.forEach((key, value) {
        Control.factory.setInitializer(key: key, initializer: value);
      });
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
