part of flutter_control;

/// Extension methods on [BuildContext] to simplify access to [CoreContext] features.
extension CoreContextExt on BuildContext {
  /// Returns the nearest [CoreContext] in the widget tree.
  CoreContext get core => this is CoreContext
      ? this as CoreContext
      : findAncestorStateOfType<CoreState>()!.element;

  /// Returns the [ControlArgs] associated with the nearest [CoreContext].
  ControlArgs get args => core.args;

  /// Shorthand for [use].
  T call<T>({dynamic key, T Function()? value, bool stateNotifier = false}) =>
      use<T>(key: key, value: value, stateNotifier: stateNotifier);

  /// Retrieves or initializes a dependency from the [CoreContext].
  ///
  /// See [CoreContext.use] for detailed information.
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

  /// Retrieves or initializes an [ElementValue] from the [CoreContext].
  ///
  /// See [CoreContext.value] for detailed information.
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

  /// Registers a dependency from an external source or parent scope.
  ///
  /// See [CoreContext.registerDependency] for detailed information.
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

  /// Retrieves a value from the [args] of the [CoreContext].
  T? get<T>({dynamic key, T? Function()? defaultValue}) =>
      args.get<T>(
        key: key,
      ) ??
      defaultValue?.call();

  /// Stores a value in the [args] of the [CoreContext].
  void set<T>({dynamic key, required T? value}) => args.add<T>(
        key: key,
        value: value,
      );

  /// Requests a rebuild of the widget associated with the [CoreContext].
  void notifyState() => core.notifyState();

  /// Registers an object for disposal with the [CoreContext].
  void register(dynamic object, [int priority = 0]) =>
      core.register(object, priority);

  /// Unregisters an object from the [CoreContext].
  void unregister(Disposable? object) => core.unregister(object);

  /// Registers a state notifier with the [CoreContext].
  /// The widget will rebuild when the object notifies of a change.
  void registerStateNotifier(Object object) => register(
      ControlObservable.of(object).subscribe((value) => notifyState()));
}
