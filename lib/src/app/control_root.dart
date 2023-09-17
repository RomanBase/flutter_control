part of flutter_control;

/// Main Widget builder.
/// [setup] - Active App settings - theme, localization, and mainly [setup.key].
/// It's expected, that [WidgetsApp] Widget will be returned.
typedef AppWidgetBuilder = Widget Function(ControlRootSetup setup, Widget home);

/// Setup of [AppState].
/// Holds case [key], [builder] and [transition]
class _AppStateBuilder {
  /// Case key of [AppState].
  final AppState key;

  /// Case builder for this state.
  final WidgetBuilder builder;

  /// Case transaction to this state.
  final CrossTransition? transition;

  /// Setup of [AppState].
  /// [key] - Case representing [AppState].
  /// [builder] - Builder for given case.
  /// [transition] - Animation from previous Widget to given case.
  const _AppStateBuilder(this.key, this.builder, this.transition);

  /// Returns case:builder entry.
  MapEntry<AppState, WidgetBuilder> get builderEntry => MapEntry(key, builder);

  /// Returns case:transition entry.
  MapEntry<AppState, CrossTransition> get transitionEntry =>
      MapEntry(key, transition!);

  /// Builds case:builder map for given states.
  static Map<AppState, WidgetBuilder> fillBuilders(
          List<_AppStateBuilder> items) =>
      items
          .asMap()
          .map<AppState, WidgetBuilder>((key, value) => value.builderEntry);

  /// Builds case:transition map for given states.
  static Map<AppState, CrossTransition> fillTransitions(
          List<_AppStateBuilder> items) =>
      items
          .where((item) => item.transition != null)
          .toList()
          .asMap()
          .map<AppState, CrossTransition>(
              (key, value) => value.transitionEntry);
}

/// Representation of App State handled by [ControlRoot].
/// [AppState.init] is considered as initial State - used during App loading.
/// [AppState.main] is considered as default App State.
/// Other predefined States (as [AppState.onboarding]) can be used to separate main App States and their flow.
/// It's possible to create custom States by extending [AppState].
///
/// Change State via [ControlRootScope] -> [Control.root].
class AppState {
  static const init = const AppState();

  static const auth = const _AppStateAuth();

  static const onboarding = const _AppStateOnboarding();

  static const main = const _AppStateMain();

  static const background = const _AppStateBackground();

  const AppState();

  _AppStateBuilder build(WidgetBuilder builder,
          {CrossTransition? transition}) =>
      _AppStateBuilder(
        this,
        builder,
        transition,
      );

  Type get key => this.runtimeType;

  operator ==(dynamic other) => other is AppState && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class _AppStateAuth extends AppState {
  const _AppStateAuth();
}

class _AppStateOnboarding extends AppState {
  const _AppStateOnboarding();
}

class _AppStateBackground extends AppState {
  const _AppStateBackground();
}

class _AppStateMain extends AppState {
  const _AppStateMain();
}

/// Holds [appKey] and [rootKey], this keys are pointing to [WidgetsApp] and [ControlRoot] Widgets.
/// Also holds current root [context]. This context can be changed within Widget Tree, but it's highly recommended to point this context to any top level Widget.
class ControlRootScope {
  /// Key of [ControlRoot] Widget. Set by framework.
  /// Accessed via [ControlRootScope].
  static const _rootKey = GlobalObjectKey<ControlRootState>(ControlRoot);

  static BuildContext? _rootContext;

  /// Gives access to global variables like [appKey] and [rootKey].
  /// Also global root [context] is accessible via this object.
  const ControlRootScope.main();

  /// Key of [ControlRoot] Widget. Set by framework.
  GlobalKey<ControlRootState> get rootKey => _rootKey;

  /// Returns [ControlRoot] Widget if is initialized.
  ControlRoot? get rootWidget => _rootKey.currentWidget as ControlRoot?;

  /// Returns [ControlRootState] of [ControlRoot] Widget if is initialized.
  ControlRootState? get rootState => _rootKey.currentState;

  /// Returns current root context.
  /// Default context set by framework don't have access to [Scaffold].
  /// This context is also changed when [AppState] is changed.
  BuildContext? get context => _rootContext;

  /// Sets new root context.
  /// Typically set [BuildContext] with access to root [Scaffold].
  /// This context is also changed when [AppState] is changed.
  set context(BuildContext? context) {
    _rootContext = context;
    printDebug('Root Context Changed: $context');
  }

  /// Checks if [ControlRoot] is initialized and root [BuildContext] is available.
  bool get isInitialized => rootKey.currentState != null && context != null;

  /// Returns current [ControlRootSetup] of [ControlRoot].
  ControlRootSetup? get setup => _rootKey.currentState?._setup;

  /// Returns current [AppState] of [ControlRoot].
  AppState? get state => _rootKey.currentState?._args.get<AppState>();

  /// Notifies state of [ControlRoot].
  /// To change [AppState] use [setAppState].
  bool notifyControlState([ControlArgs? args]) {
    if (rootKey.currentState != null && rootKey.currentState!.mounted) {
      rootKey.currentState!.notifyState(args);

      return true;
    }

    printDebug('No State found to notify.');

    return false;
  }

  /// Notifies state of [ControlRoot] and sets new [AppState].
  ///
  /// [args] - Arguments to child Builders and Widgets.
  /// [clearNavigator] - Clears root [Navigator].
  bool setAppState(AppState? state,
      {dynamic args, bool clearNavigator = true}) {
    if (clearNavigator) {
      try {
        Navigator.of(context!).popUntil((route) => route.isFirst);
      } catch (err) {
        printDebug(err.toString());
      }
    }

    return notifyControlState(ControlArgs({AppState: state})..set(args));
  }

  /// Changes [AppState] to [AppState.init]
  ///
  /// Checks [setAppState] for more info.
  bool setInitState({dynamic args, bool clearNavigator = true}) => setAppState(
        AppState.init,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.auth]
  ///
  /// Checks [setAppState] for more info.
  bool setAuthState({dynamic args, bool clearNavigator = true}) => setAppState(
        AppState.auth,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.onboarding]
  ///
  /// Checks [setAppState] for more info.
  bool setOnboardingState({dynamic args, bool clearNavigator = true}) =>
      setAppState(
        AppState.onboarding,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.main]
  ///
  /// Checks [setAppState] for more info.
  bool setMainState({dynamic args, bool clearNavigator = true}) => setAppState(
        AppState.main,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.background]
  ///
  /// Checks [setAppState] for more info.
  bool setBackgroundState({dynamic args, bool clearNavigator = true}) =>
      setAppState(
        AppState.background,
        args: args,
        clearNavigator: clearNavigator,
      );
}

/// Setup for actual [ControlRoot] and [ControlRootScope].
/// Passed to [AppWidgetBuilder].
class ControlRootSetup {
  final session = UnitId.randomId();

  final args = ControlArgs();

  /// Current [ControlTheme].
  ControlTheme? style;

  /// Parent context.
  BuildContext? context;

  /// Setup for actual [ControlRoot] and [ControlRootScope].
  ControlRootSetup._();

  /// Current [AppState].
  AppState get state => ControlRootScope.main().state ?? AppState.init;

  RoutingProvider? get routing => Control.get<RoutingProvider>();

  RouteFactory? get generateRoute => (settings) => routing?.generate(settings);

  /// Key for wrapping Widget. This key is combination of some setup properties, so Widget Tree can decide if is time to rebuild.
  ValueKey<String> get localKey => ValueKey(
      '${state.runtimeType}-${ThemeConfig.preferredTheme}-${locale ?? ''}-$session');

  GlobalObjectKey get key => GlobalObjectKey(this);

  /// Returns active [ThemeData] of [ControlTheme].
  ThemeData get theme => style!.data;

  /// Reference to [BaseLocalization] to provide actual localization settings.
  Localino? get localization => Control.get<Localino>();

  /// Current app locale that can be passed to [WidgetsApp.locale].
  Locale? get locale => localization?.currentLocale;

  /// Localization delegate for [WidgetsApp.localizationsDelegates].
  /// Pass this delegate only if using [LocalizationsDelegate] type of localization.
  /// Also use [GlobalMaterialLocalizations.delegate] and others 'Global' Flutter delegates when setting this delegate.
  LocalinoDelegate get localizationDelegate => localization!.delegate;

  /// List of supported locales for [WidgetsApp.supportedLocales].
  /// Also use [GlobalMaterialLocalizations.delegate] and others 'Global' Flutter delegates when setting supported locales.
  List<Locale> get supportedLocales => localizationDelegate.supportedLocales();

  /// Checks if [BaseLocalization] is ready and tries to localize given [localizationKey].
  /// [defaultValue] - Fallback if localization isn't ready or [localizationKey] is not found.
  String title(String localizationKey, String defaultValue) {
    if (localization != null &&
        localization!.isActive &&
        localization!.contains(localizationKey)) {
      return localization!.localize(localizationKey);
    }

    return defaultValue;
  }
}

/// Typically root Widget of whole Application.
/// Controls current localization, theme and App state.
/// Can initialize [Control] and pass arguments to [Control.initControl].
///
/// Only one [ControlRoot] is allowed in Widget Tree !
class ControlRoot extends StatefulWidget {
  /// [Control.initControl]
  final bool? debug;

  /// Config of [ControlTheme] and list of available [ThemeData].
  final ThemeConfig? theme;

  /// [Control.initControl]
  final Future Function()? initAsync;

  /// Default transition
  final CrossTransition? transition;

  /// Initial app screen, default value
  final AppState initState;

  /// List of app states. Widget builders and transitions.
  final List<_AppStateBuilder> states;

  /// Function to typically builds [WidgetsApp] or [MaterialApp] or [CupertinoApp].
  /// Builder provides [Key] and [home] widget.
  final AppWidgetBuilder app;

  final Future Function(ControlRootSetup setup)? onSetupChanged;

  /// Root [Widget] of whole app.
  /// Initializes [Control] and handles localization and theme changes.
  /// Notifies about [AppState] changes and animates Widget swapping.
  ///
  /// [debug] - Runtime debug value. This value is also provided to [BaseLocalization]. Default value is [kDebugMode].
  /// [theme] - Custom config for [ControlTheme]. Map of supported themes, default theme and custom [ControlTheme] builder.
  /// [initState] - Initial app state. Default value is [AppState.init].
  /// [states] - List of app states. [AppState.main] is by default considered as main home [Widget]. Use [AppState.main.build] to create app state. Change state by calling [Control.root().setAppState].
  /// [transition] - Custom transition between app states. Default transition is set to [CrossTransitions.fade].
  /// [app] - Builder of App - return [WidgetsApp] is expected ([MaterialApp], [CupertinoApp]). Provides [ControlRootSetup] and home [Widget]. Use [setup.key] as App key to prevent unnecessary rebuilds and disposes !
  /// [initAsync] - Custom [async] function to execute during [ControlFactory] initialization. Don't overwhelm this function - it's just for loading core settings before 'home' widget is shown.
  const ControlRoot({
    this.debug,
    this.theme,
    this.transition,
    this.initState = AppState.init,
    this.states = const [],
    required this.app,
    this.initAsync,
    this.onSetupChanged,
  }) : super(key: ControlRootScope._rootKey);

  @override
  State<StatefulWidget> createState() => ControlRootState();

  static Future<bool> initControl({
    bool? debug,
    Map<dynamic, dynamic>? entries,
    Map<Type, Initializer>? initializers,
    LocalinoOptions? localization,
    List<ControlRoute>? routes,
    Future Function()? initAsync,
  }) async {
    final initialized = Control.initControl(
      debug: debug,
      entries: entries,
      initializers: initializers,
      modules: [
        ConfigModule(),
        if (localization != null) LocalinoModule(localization, debug: debug),
        if (routes != null) RoutingModule(routes),
      ],
      initAsync: initAsync,
    );

    return initialized;
  }
}

/// [State] of [ControlRoot].
/// Handles localization, theme and App state changes.
class ControlRootState extends State<ControlRoot> {
  /// Active setup, theme, localization and state.
  final _setup = ControlRootSetup._();

  /// Combination of current State and args passed during State change.
  ControlArgs get _args => _setup.args;

  /// [AppState] - case:builder Map of [ControlRoot.states].
  late Map<dynamic, WidgetBuilder> _states;

  /// [AppState] - case:transition Map of [ControlRoot.states].
  Map<dynamic, CrossTransition>? _transitions;

  /// Subscription to global broadcast of [Localino] events.
  BroadcastSubscription? _localeSub;

  /// Subscription to global broadcast of [ThemeControl] events.
  BroadcastSubscription? _themeSub;

  @override
  void initState() {
    super.initState();

    ControlRootScope._rootContext = context;

    _args[AppState] = widget.initState;

    if (widget.theme != null) {
      _setup.style = widget.theme?.initializer(context);
      _setup.style?.setDefaultTheme();
      Control.set<ControlTheme>(value: _setup.style);
    }

    _states = _AppStateBuilder.fillBuilders(widget.states);
    _transitions = _AppStateBuilder.fillTransitions(widget.states);

    _themeSub = ThemeProvider.subscribe((value) {
      _setup.style = value;
      _notifyState(() {}, true);
    });

    _localeSub = LocalinoProvider.subscribe((args) {
      if (args?.changed ?? true) {
        _notifyState(() {}, true);
      }
    });

    _init();
  }

  void _init() async {
    await PrefsProvider.instance.mount();
    _setup.style?.setSystemTheme();
  }

  void notifyState([dynamic state]) {
    _notifyState(() {
      if (state is ControlArgs) {
        _args.combine(state);
      }
    }, state != null);
  }

  void _notifyState(VoidCallback state, [bool changed = false]) async {
    if (changed && widget.onSetupChanged != null) {
      await widget.onSetupChanged!.call(_setup);
    }

    setState(state);
  }

  @override
  Widget build(BuildContext context) {
    printDebug('BUILD CONTROL - ${_setup.localKey.value}');

    return widget.app.call(
      _setup,
      Builder(
        builder: (context) {
          ControlRootScope._rootContext = context;

          return CaseWidget(
            key: ObjectKey(_setup.session),
            activeCase: _setup.state,
            builders: _states,
            transition: widget.transition,
            transitions: _transitions,
            placeholder: (_) => Container(),
            soft: false,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _localeSub?.dispose();
    _localeSub = null;

    _themeSub?.dispose();
    _themeSub = null;
  }
}

class Rebuilder extends StatelessWidget {
  final Widget child;

  const Rebuilder({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    rebuild(context);

    return child;
  }

  static void rebuild(BuildContext context) =>
      _rebuildElement(context as Element);

  static void _rebuildElement(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_rebuildElement);
  }
}
