part of flutter_control;

class _ControlRootKey extends GlobalKey<CoreState> {
  bool get isMounted =>
      currentState?.element is RootContext && currentState!.mounted;

  RootContext get context => currentState!.element as RootContext;

  const _ControlRootKey() : super.constructor();

  @override
  String toString() {
    return '[GlobalKey#${shortHash(this)}_control_root]';
  }
}

class _ControlRootScope {
  static const key = _ControlRootKey();

  bool get isMounted =>
      key.currentState?.element is RootContext && key.currentState!.mounted;

  RootContext get context => key.currentState!.element as RootContext;

  /// Notifies state of [ControlRoot] and sets new [AppState].
  ///
  /// [args] - Arguments to child Builders and Widgets.
  /// [clearNavigator] - Clears root [Navigator].
  bool setAppState(AppState state, {bool clearNavigator = true}) {
    if (clearNavigator) {
      try {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (err) {
        printDebug(err.toString());
      }
    }

    if (isMounted) {
      context.changeAppState(state);

      return true;
    }

    printDebug('No State found to notify.');

    return false;
  }

  /// Changes [AppState] to [AppState.init]
  ///
  /// Checks [setAppState] for more info.
  bool setInitState({bool clearNavigator = true}) => setAppState(
        AppState.init,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.auth]
  ///
  /// Checks [setAppState] for more info.
  bool setAuthState({bool clearNavigator = true}) => setAppState(
        AppState.auth,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.onboarding]
  ///
  /// Checks [setAppState] for more info.
  bool setOnboardingState({bool clearNavigator = true}) => setAppState(
        AppState.onboarding,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.main]
  ///
  /// Checks [setAppState] for more info.
  bool setMainState({bool clearNavigator = true}) => setAppState(
        AppState.main,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.background]
  ///
  /// Checks [setAppState] for more info.
  bool setBackgroundState({bool clearNavigator = true}) => setAppState(
        AppState.background,
        clearNavigator: clearNavigator,
      );
}

class ControlRoot extends ControlWidget {
  final ThemeConfig? theme;
  final AppState? initState;
  final List<AppStateBuilder> states;
  final List<dynamic> stateNotifiers;
  final List<Type> builders;
  final Widget Function(RootContext context, Widget home) builder;
  final Function(RootContext context)? onSetupChanged;

  const ControlRoot({
    this.theme,
    this.initState,
    this.states = const [],
    this.stateNotifiers = const [],
    this.builders = const [],
    required this.builder,
    this.onSetupChanged,
  }) : super(key: _ControlRootScope.key);

  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    if (theme != null) {
      context<ThemeConfig>(value: () => theme!, stateNotifier: true);
      theme!.mount();
    }

    context.value<AppState>(
        value: initState ?? AppState.init, stateNotifier: true);

    stateNotifiers.forEach((element) => context.registerStateNotifier(element));
    builders.forEach((element) {
      final object = Control.get(key: element);
      if (object != null) {
        (context as RootContext).registerBuilder(object);
      }
    });
  }

  @override
  CoreContext createElement() => RootContext(this, initArgs);

  @override
  Widget build(CoreContext context) {
    printAction(() =>
        'BUILD CONTROL ROOT: ${Parse.name((context as RootContext).appState)} | ${ThemeConfig.preferredTheme} | ${builders.map((e) => Control.get(key: e)?.toString()).join(' | ')}');

    return builder(
      context as RootContext,
      ControlBuilder<AppState>(
        control: context.value<AppState>(),
        valueConverter: (_) => context.appState,
        builder: (context, value) => CaseWidget<AppState>(
          activeCase: value,
          builders: AppStateBuilder.fillBuilders(states),
          transitions: AppStateBuilder.fillTransitions(states),
        ),
      ),
    );
  }
}

class RootContext extends CoreContext {
  static RootContext? of(BuildContext context) =>
      context.findRootAncestorStateOfType<CoreState>()?.element as RootContext;

  AppState get appState => value<AppState>().value ?? AppState.init;

  RootContext(
    super.widget,
    super.initArgs,
  );

  void registerBuilder(dynamic object) {
    register(ControlObservable.of(object).subscribe((value) {
      _rebuildElement(this);
      (widget as ControlRoot).onSetupChanged?.call(this);
    }));
  }

  void _rebuildElement(Element el) {
    el.markNeedsBuild();
    el.visitChildren(_rebuildElement);
  }

  void changeAppState(AppState state) => value<AppState>().value = state;

  void changeTheme(dynamic key, [bool preferred = true]) =>
      get<ThemeConfig>()?.changeTheme(key, preferred);

  @override
  void notifyState() {
    super.notifyState();

    (widget as ControlRoot).onSetupChanged?.call(this);
  }
}
