part of control_core;

abstract class ControlModule<T> implements Comparable<ControlModule> {
  Type get key => T;

  T? module;

  int priority = -1;

  Map get entries => {key: module};

  Map<Type, Initializer> get initializers => {};

  bool get preInit => priority > 0;

  bool get isInitialized => module != null;

  Map<Type, Initializer> get subModules => {};

  static bool initControl(ControlModule module, {Map? args, bool? debug}) =>
      Control.initControl(
        debug: debug ?? true,
        modules: [
          ...module.getInactiveSubmodules(args: args),
          module,
        ],
      );

  static List<ControlModule> fillModules(List<ControlModule> modules) {
    modules = _fillModules(modules);
    modules.sort();

    return modules;
  }

  static List<ControlModule> _fillModules(List<ControlModule> modules) {
    final output = List.of(modules);

    modules.forEach((element) {
      element.subModules.forEach((key, value) {
        if (!output.any((element) => element.key == key)) {
          output.addAll(_fillModules([value.call(null)]));
        }
      });
    });

    return output;
  }

  void initModule() {
    if (Control.isInitialized) {
      module = Control.get<T>(key: key);
    }
  }

  void initStore({bool includeSubModules = false}) {
    _initModuleStore(this);

    if (includeSubModules) {
      getInactiveSubmodules().forEach((element) {
        _initModuleStore(element);
      });
    }
  }

  static void _initModuleStore(ControlModule module) {
    if (module.entries.isNotEmpty) {
      module.entries.forEach((key, value) {
        Control.set(key: key, value: value);
      });
    }

    if (module.initializers.isNotEmpty) {
      module.initializers.forEach((key, value) {
        Control.factory.setInitializer(key: key, initializer: value);
      });
    }
  }

  List<ControlModule> getInactiveSubmodules({Map? args}) {
    final modules = <ControlModule>[];

    if (subModules.isNotEmpty) {
      if (Control.isInitialized) {
        subModules.forEach((key, value) {
          if (!Control.factory.containsKey(key)) {
            modules.add(value(args));
          }
        });
      } else {
        subModules.forEach((key, value) {
          modules.add(value(args));
        });
      }
    }

    return modules;
  }

  Future initWithSubModules({Map? args}) async {
    final modules = [
      this,
      ...getInactiveSubmodules(args: args),
    ];

    modules.sort();

    for (ControlModule module in modules) {
      if (module.preInit) {
        await module.init();
      }
    }

    await FutureBlock.wait([
      for (ControlModule module in modules)
        if (!module.preInit) module.init(),
    ]);
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
