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

  RootContext? get context => key.currentState?.element as RootContext;

  BuildContext? get navigationContext => context?.navigationContext;

  /// Notifies state of [ControlRoot] and sets new [AppState].
  ///
  /// [args] - Arguments to child Builders and Widgets.
  /// [clearNavigator] - Clears root [Navigator].
  bool setAppState(AppState state, {bool clearNavigator = true}) {
    return context?.changeAppState(state, clearNavigator: clearNavigator) ??
        false;
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

/// The root widget for the control framework. It initializes the theme, application states,
/// and other global dependencies. It's the main entry point for a Control-based application structure.
class ControlRoot extends ControlWidget {
  final ThemeConfig? theme;
  final AppState? initState;
  final List<AppStateBuilder> states;
  final List<dynamic> stateNotifiers;
  final List<dynamic> builders;
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
    super.initArgs,
  }) : super(key: _ControlRootScope.key);

  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    if (theme != null) {
      context
          .use<ThemeConfig>(value: () => theme!, stateNotifier: true)
          .mount();
    }

    context.value<AppState>(
        value: initState ?? AppState.init, stateNotifier: true);

    _initNotifiers(context as RootContext);
  }

  void _initNotifiers(RootContext context) async {
    stateNotifiers.forEach((element) {
      Control.evaluate(element, (object) {
        if (object != null) {
          context.registerStateNotifier(object);
        }
      });
    });

    builders.forEach((element) {
      Control.evaluate(element, (object) {
        if (object != null) {
          context.registerBuilder(object);
        }
      });
    });
  }

  @override
  CoreContext createElement() => RootContext(this);

  @override
  Widget build(CoreContext context) {
    final root = context as RootContext;
    printAction(() =>
        'BUILD CONTROL ROOT: ${Parse.name(root.appState)} | ${ThemeConfig.preferredTheme} --- ${builders.map((e) => Control.get(key: e)?.toString()).join(' | ')}');

    return builder(
      root,
      ControlBuilder<AppState>(
        control: context.value<AppState>(),
        valueConverter: (_) => context.appState,
        builder: (context, value) {
          root.navigationContext = context;

          return CaseWidget<AppState>(
            activeCase: value,
            builders: AppStateBuilder.fillBuilders(states),
            transitions: AppStateBuilder.fillTransitions(states),
          );
        },
      ),
    );
  }
}

/// The [CoreContext] for the [ControlRoot] widget.
/// Provides access to global app state and theme configuration.
class RootContext extends CoreContext {
  static RootContext? of(BuildContext context) =>
      context.findRootAncestorStateOfType<CoreState>()?.element as RootContext;

  AppState get appState => value<AppState>().value ?? AppState.init;

  ThemeConfig? get themeConfig => get<ThemeConfig>();

  BuildContext? navigationContext;

  RootContext(super.widget);

  void registerBuilder(dynamic object) {
    register(ControlObservable.of(object).subscribe(
      (value) {
        _rebuildElementTree(this);
        (widget as ControlRoot).onSetupChanged?.call(this);
      },
      current: false,
    ));
  }

  void _rebuildElementTree(Element el) {
    el.markNeedsBuild();
    el.visitChildren(_rebuildElementTree);
  }

  bool changeAppState(AppState state, {bool clearNavigator = true}) {
    if (clearNavigator && navigationContext != null) {
      Navigator.of(navigationContext!).popUntil((route) => route.isFirst);
    }

    value<AppState>().value = state;

    return true;
  }

  bool changeTheme(dynamic key, [bool preferred = true]) =>
      themeConfig?.changeTheme(key, preferred) ?? false;

  @override
  void notifyState() {
    super.notifyState();

    (widget as ControlRoot).onSetupChanged?.call(this);
  }
}
