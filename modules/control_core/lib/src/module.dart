part of '../core.dart';

abstract class ControlModule<T> implements Comparable<ControlModule> {
  Type get key => T;

  T? module;

  int priority = -1;

  Map get entries => {key: module};

  Map<Type, InitFactory> get factories => {};

  bool get preInit => priority > 0;

  bool get isInitialized => module != null;

  Map<Type, InitFactory> get subModules => {};

  static bool initControl(ControlModule module, {Map? args, bool? debug}) =>
      Control.initControl(
        debug: debug ?? true,
        modules: [
          ...module.getInactiveSubmodules(Control.factory, args: args),
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

    for (final element in modules) {
      element.subModules.forEach((key, value) {
        if (!output.any((element) => element.key == key)) {
          output.addAll(_fillModules([value.call(null)]));
        }
      });
    }

    return output;
  }

  void initModule() {
    if (Control.isInitialized) {
      module = Control.get<T>(key: key);
    }
  }

  void initStore(ControlFactory factory, {bool includeSubModules = false}) {
    _initModuleStore(factory, this);

    if (includeSubModules) {
      getInactiveSubmodules(factory).forEach((element) {
        _initModuleStore(factory, element);
      });
    }
  }

  static void _initModuleStore(ControlFactory factory, ControlModule module) {
    if (module.entries.isNotEmpty) {
      module.entries.forEach((key, value) {
        factory.set(key: key, value: value);
      });
    }

    if (module.factories.isNotEmpty) {
      module.factories.forEach((key, value) {
        factory.add(key: key, init: value);
      });
    }
  }

  List<ControlModule> getInactiveSubmodules(ControlFactory factory,
      {Map? args}) {
    final modules = <ControlModule>[];

    if (subModules.isNotEmpty) {
      if (factory.isInitialized) {
        subModules.forEach((key, value) {
          if (!factory.containsKey(key)) {
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

  Future initWithSubModules(ControlFactory factory, {Map? args}) async {
    final modules = [
      this,
      ...getInactiveSubmodules(factory, args: args),
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

  Future init();

  int compareTo(ControlModule other) {
    if (priority > other.priority) {
      return -1;
    } else if (priority < other.priority) {
      return 1;
    }

    return 0;
  }
}

class ControlProvider extends ControlModule<void> {
  @override
  Type get key => runtimeType;

  @override
  ControlProvider get module => this;

  @override
  Map get entries => {};

  @override
  Future init() async {}
}
