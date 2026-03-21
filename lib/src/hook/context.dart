part of flutter_control;

extension CoreContextExt on BuildContext {
  CoreContext get core => this is CoreContext
      ? this as CoreContext
      : findAncestorStateOfType<CoreState>()!.element;

  ControlArgs get args => core.args;

  T call<T>({dynamic key, T Function()? value, bool stateNotifier = false}) =>
      use<T>(key: key, value: value, stateNotifier: stateNotifier);

  T use<T>({
    dynamic key,
    required T Function()? value,
    bool stateNotifier = false,
    void Function(T object)? dispose,
  }) =>
      core.use(
        key: key,
        value: value,
        stateNotifier: stateNotifier,
        dispose: dispose,
      );

  ElementValue<T> value<T>({
    dynamic key,
    T? value,
    bool stateNotifier = false,
  }) =>
      core.value(
        key: key,
        value: value,
        stateNotifier: stateNotifier,
      );

  T? registerDependency<T>({
    dynamic key,
    bool scope = false,
    bool stateNotifier = false,
  }) =>
      core.registerDependency(
        key: key,
        scope: scope,
        stateNotifier: stateNotifier,
      );

  T? get<T>({dynamic key, T? Function()? defaultValue}) =>
      args.get<T>(
        key: key,
      ) ??
      defaultValue?.call();

  void set<T>({dynamic key, required T? value}) => args.add<T>(
        key: key,
        value: value,
      );

  void notifyState() => core.notifyState();

  void register(dynamic object, [int priority = 0]) =>
      core.register(object, priority);

  void unregister(Disposable? object) => core.unregister(object);

  void registerStateNotifier(Object object) => register(
      ControlObservable.of(object).subscribe((value) => notifyState()));
}
