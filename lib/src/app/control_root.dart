part of '../../control.dart';

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
  /// Configuration for the application's theme.
  final ThemeConfig? theme;

  /// The initial [AppState] to use when the app starts. Defaults to [AppState.init].
  final AppState? initState;

  /// A list of [AppStateBuilder]s that define the available states and their builders.
  final List<AppStateBuilder> states;

  /// A list of objects that notify the [ControlRoot] of state changes (e.g., [Observable]s).
  final List<dynamic> stateNotifiers;

  /// A list of additional builders to be evaluated and registered.
  final List<dynamic> builders;

  /// A function that builds the root widget tree, providing access to the [RootContext].
  final Widget Function(RootContext context, Widget home) builder;

  /// A callback that is triggered when the application's global setup changes (e.g., theme or language).
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
  Widget build(BuildContext context) {
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
  /// Returns the nearest [RootContext] in the widget tree from the given [context].
  static RootContext? of(BuildContext context) =>
      context.findRootAncestorStateOfType<CoreState>()?.element as RootContext;

  /// Returns the current active [AppState].
  AppState get appState => value<AppState>().value ?? AppState.init;

  /// Returns the application's [ThemeConfig].
  ThemeConfig? get themeConfig => get<ThemeConfig>();

  /// The [BuildContext] for the root navigator.
  BuildContext? navigationContext;

  RootContext(super.widget);

  /// Registers an [object] that triggers a full app rebuild when changed.
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

  /// Changes the current [AppState].
  /// [state] - The new state.
  /// [clearNavigator] - If true, pops all routes from the navigator until the first route.
  bool changeAppState(AppState state, {bool clearNavigator = true}) {
    if (clearNavigator && navigationContext != null) {
      Navigator.of(navigationContext!).popUntil((route) => route.isFirst);
    }

    value<AppState>().value = state;

    return true;
  }

  /// Changes the current theme.
  /// [key] - The key identifying the new theme.
  /// [preferred] - If true, saves the theme as the user's preference.
  bool changeTheme(dynamic key, [bool preferred = true]) =>
      themeConfig?.changeTheme(key, preferred) ?? false;

  @override
  void notifyState() {
    super.notifyState();

    (widget as ControlRoot).onSetupChanged?.call(this);
  }
}
