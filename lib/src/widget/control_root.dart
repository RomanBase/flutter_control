import 'package:flutter_control/core.dart';

/// Holder of current root context.
/// Accessed via [ControlScope].
final _context = ActionControl.broadcast<BuildContext>();

/// Key of [ControlRoot] Widget. Set by framework.
/// Accessed via [ControlScope].
const _rootKey = GlobalObjectKey<ControlRootState>(ControlRoot);

/// Key passed to [ControlRootSetup] to be used as key for [WidgetsApp] Widget.
/// Accessed via [ControlScope].
const _appKey = GlobalObjectKey(AppWidgetBuilder);

/// Main Widget builder.
/// [setup] - Active App settings - theme, localization, and mainly [setup.key].
/// It's expected, that [WidgetsApp] Widget will be returned.
typedef AppWidgetBuilder = Widget Function(ControlRootSetup setup, Widget home);

/// Setup of [AppState].
/// Holds case [key], [builder] and [transition]
class AppStateSetup {
  /// Case key of [AppState].
  final dynamic key;

  /// Case builder for this state.
  final WidgetBuilder builder;

  /// Case transaction to this state.
  final CrossTransition? transition;

  /// Setup of [AppState].
  /// [key] - Case representing [AppState].
  /// [builder] - Builder for given case.
  /// [transition] - Animation from previous Widget to given case.
  const AppStateSetup(this.key, this.builder, this.transition);

  /// Returns case:builder entry.
  MapEntry<dynamic, WidgetBuilder> get builderEntry => MapEntry(key, builder);

  /// Returns case:transition entry.
  MapEntry<dynamic, CrossTransition> get transitionEntry =>
      MapEntry(key, transition!);

  /// Builds case:builder map for given states.
  static Map<dynamic, WidgetBuilder> fillBuilders(List<AppStateSetup> items) =>
      items
          .asMap()
          .map<dynamic, WidgetBuilder>((key, value) => value.builderEntry);

  /// Builds case:transition map for given states.
  static Map<dynamic, CrossTransition> fillTransitions(
          List<AppStateSetup> items) =>
      items
          .where((item) => item.transition != null)
          .toList()
          .asMap()
          .map<dynamic, CrossTransition>((key, value) => value.transitionEntry);
}

/// Representation of App State handled by [ControlRoot].
/// [AppState.init] is considered as initial State - used during App loading.
/// [AppState.main] is considered as default App State.
/// Other predefined States (as [AppState.onboarding]) can be used to separate main App States and their flow.
/// It's possible to create custom States by extending [AppState].
///
/// Change State via [ControlScope] -> [Control.root].
class AppState {
  static const init = const AppState();

  static const auth = const _AppStateAuth();

  static const onboarding = const _AppStateOnboarding();

  static const main = const _AppStateMain();

  static const background = const _AppStateBackground();

  const AppState();

  AppStateSetup build(WidgetBuilder builder, {CrossTransition? transition}) =>
      AppStateSetup(
        this, //TODO: this or key ???
        builder,
        transition,
      );

  dynamic get key => this.runtimeType;

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
class ControlScope {
  /// Gives access to global variables like [appKey] and [rootKey].
  /// Also global root [context] is accessible via this object.
  const ControlScope();

  /// Key of [ControlRoot] Widget. Set by framework.
  GlobalKey<ControlRootState> get rootKey => _rootKey;

  /// Key passed to [ControlRootSetup] to be used as key for [WidgetsApp] Widget.
  GlobalKey get appKey => _appKey;

  /// Returns [ControlRoot] Widget if is initialized.
  ControlRoot? get rootWidget => _rootKey.currentWidget as ControlRoot?;

  /// Returns [ControlRootState] of [ControlRoot] Widget if is initialized.
  ControlRootState? get rootState => _rootKey.currentState;

  /// Returns current root context.
  /// Default context set by framework don't have access to [Scaffold].
  /// This context is also changed when [AppState] is changed.
  BuildContext? get context => _context.value;

  /// Sets new root context.
  /// Typically set [BuildContext] with access to root [Scaffold].
  /// This context is also changed when [AppState] is changed.
  set context(BuildContext? context) => _context.value = context;

  /// Checks if [ControlRoot] is initialized and root [BuildContext] is available.
  bool get isInitialized => rootKey.currentState != null && context != null;

  /// Subscribe to listen about [BuildContext] changes.
  ActionControlObservable get rootContextSub => _context.sub;

  /// Returns current [ControlRootSetup] of [ControlRoot].
  ControlRootSetup? get setup => _rootKey.currentState?._setup;

  /// Notifies state of [ControlRoot].
  /// To change [AppState] use [setAppState].
  bool notifyControlState([ControlArgs? args]) {
    if (rootKey.currentState != null && rootKey.currentState!.mounted) {
      rootKey.currentState!.notifyState(args);

      return true;
    }

    printDebug('ControlRoot is not in Widget Tree! [ControlScope.rootKey]');
    printDebug('Trying to notify ControlScope.scopeKey ..');

    final currentState = appKey.currentState;

    if (currentState != null && currentState.mounted) {
      if (currentState is StateNotifier) {
        (currentState as StateNotifier).notifyState(args);
      } else {
        printDebug(
            'Found State is not StateNotifier, Trying to call setState directly..');
        // ignore: invalid_use_of_protected_member
        appKey.currentState!.setState(() {});
      }

      return true;
    }

    printDebug('No State found to notify.');

    return false;
  }

  /// Notifies state of [ControlRoot] and sets new [AppState].
  ///
  /// [args] - Arguments to child Builders and Widgets.
  /// [clearNavigator] - Clears root [Navigator].
  bool setAppState(AppState? state, {dynamic args, bool clearNavigator: true}) {
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
  bool setInitState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.init,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.auth]
  ///
  /// Checks [setAppState] for more info.
  bool setAuthState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.auth,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.onboarding]
  ///
  /// Checks [setAppState] for more info.
  bool setOnboardingState({dynamic args, bool clearNavigator: true}) =>
      setAppState(
        AppState.onboarding,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.main]
  ///
  /// Checks [setAppState] for more info.
  bool setMainState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.main,
        args: args,
        clearNavigator: clearNavigator,
      );

  /// Changes [AppState] to [AppState.background]
  ///
  /// Checks [setAppState] for more info.
  bool setBackgroundState({dynamic args, bool clearNavigator: true}) =>
      setAppState(
        AppState.background,
        args: args,
        clearNavigator: clearNavigator,
      );
}

/// Setup for actual [ControlRoot] and [ControlScope].
/// Passed to [AppWidgetBuilder].
class ControlRootSetup {
  final session = UnitId.randomId();

  /// App key for [WidgetsApp] Widget. This key is same as [ControlScope.appKey].
  Key? key;

  /// Current [AppState].
  AppState? state;

  /// Arguments passed to [ControlRootState]. Typically passed when changing state.
  ControlArgs? args;

  /// Current [ControlTheme].
  ControlTheme? style;

  /// Parent context.
  BuildContext? context;

  /// Key for wrapping Widget. This key is combination of some setup properties, so Widget Tree can decide if is time to rebuild.
  ObjectKey get _localKey => ObjectKey(session.hashCode ^
      (localization?.locale.hashCode ?? 0xFF) ^
      state.hashCode ^
      (style?.data.hashCode ?? 0xFF));

  /// Setup for actual [ControlRoot] and [ControlScope].
  /// [key] - [_appKey] - [ControlScope.appKey].
  /// [state] - Active app state.
  /// [args] - Arguments passed with state change.
  /// [style] - Active theme.
  /// [context] - Parent context.
  ControlRootSetup({
    this.key,
    this.state,
    this.args,
    this.style,
    this.context,
  });

  /// Returns active [ThemeData] of [ControlTheme].
  ThemeData get theme => style!.data;

  /// Reference to [BaseLocalization] to provide actual localization settings.
  BaseLocalization? get localization => Control.localization;

  /// Current app locale that can be passed to [WidgetsApp.locale].
  Locale? get locale => localization!.currentLocale;

  /// Localization delegate for [WidgetsApp.localizationsDelegates].
  /// Pass this delegate only if using [LocalizationsDelegate] type of localization.
  /// Also use [GlobalMaterialLocalizations.delegate] and others 'Global' Flutter delegates when setting this delegate.
  BaseLocalizationDelegate get localizationDelegate => localization!.delegate;

  /// List of supported locales for [WidgetsApp.supportedLocales].
  /// Also use [GlobalMaterialLocalizations.delegate] and others 'Global' Flutter delegates when setting supported locales.
  List<Locale> get supportedLocales => localizationDelegate.supportedLocales();

  /// Checks if [BaseLocalization] is ready and tries to localize given [localizationKey].
  /// [defaultValue] - Fallback if localization isn't ready or [localizationKey] is not found.
  String? title(String localizationKey, String defaultValue) {
    if (localization != null &&
        localization!.isActive &&
        localization!.contains(localizationKey)) {
      return localization!.localize(localizationKey);
    }

    return defaultValue;
  }

  /// Creates copy of current setup.
  ControlRootSetup copyWith({
    Key? key,
    AppState? state,
    ControlArgs? args,
    ControlTheme? style,
    BuildContext? context,
  }) {
    return new ControlRootSetup(
      key: key ?? this.key,
      state: state ?? this.state,
      args: args ?? this.args,
      style: style ?? this.style,
      context: context ?? this.context,
    );
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

  /// [Control.initControl]
  final LocalizationConfig? localization;

  /// [Control.initControl]
  final Map? entries;

  /// [Control.initControl]
  final Map<Type, Initializer>? initializers;

  /// [Control.initControl]
  final Injector? injector;

  /// [Control.initControl]
  final List<ControlRoute>? routes;

  /// Config of [ControlTheme] and list of available [ThemeData].
  final ThemeConfig? theme;

  /// [Control.initControl]
  final Future Function()? initAsync;

  /// Default transition
  final CrossTransition? transition;

  /// Initial app screen, default value
  final AppState initState;

  /// List of app states. Widget builders and transitions.
  final List<AppStateSetup>? states;

  /// Function to typically builds [WidgetsApp] or [MaterialApp] or [CupertinoApp].
  /// Builder provides [Key] and [home] widget.
  final AppWidgetBuilder app;

  final Future Function(ControlRootSetup setup)? onSetupChanged;

  /// Root [Widget] of whole app.
  /// Initializes [Control] and handles localization and theme changes.
  /// Notifies about [AppState] changes and animates Widget swapping.
  ///
  /// [debug] - Runtime debug value. This value is also provided to [BaseLocalization]. Default value is [kDebugMode].
  /// [localization] - Custom config for [BaseLocalization]. Map of supported locales, default locale and loading rules.
  /// [entries] - Default items to store in [ControlFactory]. Use [Control.get] to retrieve this objects and [Control.set] to add new ones. All objects are initialized - [Initializable.init] and [DisposeHandler.preferSoftDispose] is set.
  /// [initializers] - Default factory initializers to store in [ControlFactory] Use [Control.init] or [Control.get] to retrieve concrete objects.
  /// [injector] - Property Injector to use right after object initialization. Use [BaseInjector] for [Type] based injection. Currently not used a lot...
  /// [routes] - Set of routes for [RouteStore]. Use [ControlRoute.build] to build routes and [ControlRoute.of] to retrieve route. It's possible to alter route with new settings, path or transition.
  /// [theme] - Custom config for [ControlTheme]. Map of supported themes, default theme and custom [ControlTheme] builder.
  /// [initState] - Initial app state. Default value is [AppState.init].
  /// [states] - List of app states. [AppState.main] is by default considered as main home [Widget]. Use [AppState.main.build] to create app state. Change state by calling [Control.root().setAppState].
  /// [transition] - Custom transition between app states. Default transition is set to [CrossTransitions.fade].
  /// [app] - Builder of App - return [WidgetsApp] is expected ([MaterialApp], [CupertinoApp]). Provides [ControlRootSetup] and home [Widget]. Use [setup.key] as App key to prevent unnecessary rebuilds and disposes !
  /// [initAsync] - Custom [async] function to execute during [ControlFactory] initialization. Don't overwhelm this function - it's just for loading core settings before 'home' widget is shown.
  const ControlRoot({
    this.debug,
    this.localization,
    this.entries,
    this.initializers,
    this.injector,
    this.routes,
    this.theme,
    this.transition,
    this.initState: AppState.init,
    this.states,
    required this.app,
    this.initAsync,
    this.onSetupChanged,
  }) : super(key: _rootKey);

  @override
  State<StatefulWidget> createState() => ControlRootState();
}

/// [State] of [ControlRoot].
/// Handles localization, theme and App state changes.
class ControlRootState extends State<ControlRoot> implements StateNotifier {
  /// Combination of current State and args passed during State change.
  final _args = ControlArgs();

  /// Active setup, theme, localization and state.
  final _setup = ControlRootSetup();

  /// Default theme config. Used to build [ControlTheme].
  late ThemeConfig _theme;

  /// [AppState] - case:builder Map of [ControlRoot.states].
  Map<dynamic, WidgetBuilder>? _states;

  /// [AppState] - case:transition Map of [ControlRoot.states].
  Map<dynamic, CrossTransition>? _transitions;

  /// Subscription to global broadcast of [BaseLocalization] events.
  BroadcastSubscription? _localeSub;

  /// Subscription to global broadcast of [ThemeControl] events.
  BroadcastSubscription? _themeSub;

  @override
  void initState() {
    super.initState();

    _context.value = context;
    _args[AppState] = widget.initState;

    _states = AppStateSetup.fillBuilders(widget.states!);
    _transitions = AppStateSetup.fillTransitions(widget.states!);

    final initState = widget.initState.build(
      (context) => InitLoader.of(
        builder: (context) => Container(
          color: Theme.of(context).canvasColor,
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
        ),
      ),
    );

    if (!_states!.containsKey(initState.key)) {
      _states![initState.key] = initState.builder;
    }

    _theme = widget.theme ??
        ThemeConfig(
          builder: (context) => ControlTheme(context),
          initTheme: ThemeConfig.platformBrightness,
          themes: {
            Brightness.light: (_) => ThemeData.light(),
            Brightness.dark: (_) => ThemeData.dark(),
          },
        );

    _setup.key = _appKey;
    _setup.style = _theme.initializer(context)..setDefaultTheme();

    _themeSub = ControlTheme.subscribeChanges((value) {
      _notifyState(() {
        _setup.style = value;
      }, true);
    });

    _localeSub = BaseLocalization.subscribeChanges((args) {
      if (args!.changed!) {
        _notifyState(() {}, true);
      }
    });

    _initControl();
  }

  @override
  void notifyState([state]) {
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

  void _initControl() async {
    final initialized = Control.initControl(
      debug: widget.debug,
      localization: widget.localization,
      entries: widget.entries,
      initializers: {
        if (widget.initializers != null) ...widget.initializers!,
        ...{ControlTheme: _theme.initializer},
      },
      injector: widget.injector,
      routes: widget.routes,
      initAsync: () => FutureBlock.wait([
        _loadTheme(),
        widget.initAsync?.call(),
      ]),
    );

    if (initialized) {
      await Control.factory.onReady();
      _notifyState(() {}, true);
    }
  }

  Future<void> _loadTheme() async => _setup.style!.setSystemTheme();

  @override
  Widget build(BuildContext context) {
    _setup.context = context;
    _setup.state = _args.get<AppState>();
    _setup.args = _args;

    printDebug('BUILD CONTROL');

    return Container(
      key: _setup._localKey,
      child: widget.app(
        _setup,
        Builder(builder: (context) {
          _context.value = context;

          return CaseWidget(
            activeCase: _setup.state,
            builders: _states!,
            transition: widget.transition,
            transitions: _transitions,
            placeholder: (_) => Container(
              color: Theme.of(context).canvasColor,
            ),
          );
        }),
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
