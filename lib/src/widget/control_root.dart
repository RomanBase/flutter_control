import 'package:flutter_control/core.dart';

/// Holder of current root context.
final _context = ActionControl.broadcast<BuildContext>();

const _rootKey = GlobalObjectKey<ControlRootState>(ControlRoot);
const _appKey = GlobalObjectKey(AppWidgetBuilder);

typedef AppWidgetBuilder = Widget Function(ControlRootSetup setup, Widget home);

class AppStateSetup {
  final dynamic key;
  final WidgetBuilder builder;
  final CrossTransition transition;

  const AppStateSetup(this.key, this.builder, this.transition);

  MapEntry<dynamic, WidgetBuilder> get builderEntry => MapEntry(key, builder);

  MapEntry<dynamic, CrossTransition> get transitionEntry => MapEntry(key, transition);

  static Map<dynamic, WidgetBuilder> fillBuilders(List<AppStateSetup> items) => items.asMap().map<dynamic, WidgetBuilder>((key, value) => value.builderEntry);

  static Map<dynamic, CrossTransition> fillTransitions(List<AppStateSetup> items) => items.where((item) => item.transition != null).toList().asMap().map<dynamic, CrossTransition>((key, value) => value.transitionEntry);
}

class AppState {
  static const init = const AppState();

  static const auth = const _AppStateAuth();

  static const onboarding = const _AppStateOnboarding();

  static const main = const _AppStateMain();

  static const background = const _AppStateBackground();

  const AppState();

  AppStateSetup build(WidgetBuilder builder, {CrossTransition transition}) => AppStateSetup(
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

class ControlScope {
  const ControlScope();

  GlobalKey<ControlRootState> get rootKey => _rootKey;

  GlobalKey get appKey => _appKey;

  ControlRoot get rootWidget => _rootKey.currentWidget;

  ControlRootState get rootState => _rootKey.currentState;

  /// Returns current context from [contextHolder]
  BuildContext get context => _context.value;

  bool get isInitialized => rootKey.currentState != null && context != null;

  /// Sets new root context to [contextHolder]
  set context(BuildContext context) => _context.value = context;

  ActionControlStream get rootContextSub => _context.sub;

  bool notifyControlState([ControlArgs args]) {
    if (rootKey.currentState != null && rootKey.currentState.mounted) {
      rootKey.currentState.notifyState(args);

      return true;
    }

    printDebug('ControlRoot is not in Widget Tree! [ControlScope.rootKey]');
    printDebug('Trying to notify ControlScope.scopeKey ..');

    final currentState = appKey.currentState;

    if (currentState != null && currentState.mounted) {
      if (currentState is StateNotifier) {
        (currentState as StateNotifier).notifyState(args);
      } else {
        printDebug('Found State is not StateNotifier, Trying to call setState directly..');
        // ignore: invalid_use_of_protected_member
        appKey.currentState.setState(() {});
      }

      return true;
    }

    printDebug('No State found to notify.');

    return false;
  }

  bool setAppState(AppState state, {dynamic args, bool clearNavigator: true}) {
    if (clearNavigator) {
      try {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (err) {
        printDebug(err.toString());
      }
    }

    return notifyControlState(ControlArgs({AppState: state})..set(args));
  }

  bool setInitState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.init,
        args: args,
        clearNavigator: clearNavigator,
      );

  bool setAuthState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.auth,
        args: args,
        clearNavigator: clearNavigator,
      );

  bool setOnboardingState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.onboarding,
        args: args,
        clearNavigator: clearNavigator,
      );

  bool setMainState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.main,
        args: args,
        clearNavigator: clearNavigator,
      );

  bool setBackgroundState({dynamic args, bool clearNavigator: true}) => setAppState(
        AppState.background,
        args: args,
        clearNavigator: clearNavigator,
      );
}

class ControlRootSetup {
  Key key;
  AppState state;
  ControlArgs args;
  ControlTheme style;
  BuildContext context;

  ObjectKey get _localKey => ObjectKey(localization.locale.hashCode ^ state.hashCode ^ style.data.hashCode);

  ControlRootSetup({
    this.key,
    this.state,
    this.args,
    this.style,
    this.context,
  });

  ThemeData get theme => style.data;

  BaseLocalization get localization => Control.localization();

  Locale get locale => localization.currentLocale;

  BaseLocalizationDelegate get localizationDelegate => localization.delegate;

  List<Locale> get supportedLocales => localizationDelegate.supportedLocales();

  String title(String localizationKey, String defaultValue) {
    if (localization.isActive && localization.contains(localizationKey)) {
      return localization.localize(localizationKey);
    }

    return defaultValue;
  }

  ControlRootSetup copyWith({
    Key key,
    AppState state,
    ControlArgs args,
    ControlTheme style,
    BuildContext context,
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

/// Root [Widget] of whole app.
/// Initializes [Control] - [Control.initControl]: localization, entries, initializers, routes and more..
///
/// Also handles localization, theme changes and App states.
class ControlRoot extends StatefulWidget {
  /// [Control.initControl]
  final bool debug;

  /// [Control.initControl]
  final LocalizationConfig localization;

  /// [Control.initControl]
  final Map entries;

  /// [Control.initControl]
  final Map<Type, Initializer> initializers;

  /// [Control.initControl]
  final Injector injector;

  /// [Control.initControl]
  final List<ControlRoute> routes;

  /// [Control.initControl]
  final ThemeConfig theme;

  /// [Control.initControl]
  final Future Function() initAsync;

  /// Default transition
  final CrossTransition transition;

  /// Initial app screen, default value
  final AppState initState;

  /// List of app states. Widget builders and transitions.
  final List<AppStateSetup> states;

  /// Function to typically builds [WidgetsApp] or [MaterialApp] or [CupertinoApp].
  /// Builder provides [Key] and [home] widget.
  final AppWidgetBuilder app;

  /// Root [Widget] of whole app.
  /// Initializes [Control] and handles localization and theme changes.
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
    @required this.states,
    @required this.app,
    this.initAsync,
  }) : super(key: _rootKey);

  @override
  State<StatefulWidget> createState() => ControlRootState();
}

/// Creates State for BaseApp.
/// AppControl and MaterialApp is build here.
/// This State is meant to be used as root.
/// BuildContext from local Builder is used as root context.
class ControlRootState extends State<ControlRoot> implements StateNotifier {
  final _args = ControlArgs();

  final _setup = ControlRootSetup();

  ThemeConfig _theme;
  Map<dynamic, WidgetBuilder> _states;
  Map<dynamic, CrossTransition> _transitions;

  get appStateKey => _args.get<AppState>()?.key;

  BroadcastSubscription _localeSub;

  BroadcastSubscription _themeSub;

  @override
  void initState() {
    super.initState();

    _context.value = context;
    _args[AppState] = widget.initState;

    _states = AppStateSetup.fillBuilders(widget.states);
    _transitions = AppStateSetup.fillTransitions(widget.states);

    if (!_states.containsKey(widget.initState.key)) {
      final state = widget.initState.build(
        (context) => InitLoader.of(
          builder: (context) => Container(
            color: Theme.of(context).canvasColor,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
          ),
        ),
      );

      _states[state.key] = state.builder;
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
    _setup.style = widget.theme.initializer(context)..setDefaultTheme();

    _themeSub = ControlTheme.subscribeChanges((value) {
      setState(() {
        _setup.style = value;
      });
    });

    _localeSub = BaseLocalization.subscribeChanges((args) {
      if (args.changed) {
        setState(() {});
      }
    });

    _initControl();
  }

  @override
  void notifyState([state]) {
    if (state is ControlArgs) {
      _args.combine(state);
    }

    setState(() {});
  }

  void _initControl() async {
    final initialized = Control.initControl(
      debug: widget.debug,
      localization: widget.localization,
      entries: widget.entries,
      initializers: widget.initializers,
      injector: widget.injector,
      routes: widget.routes,
      theme: _theme.initializer,
      initAsync: () => FutureBlock.wait([
        _loadTheme(),
        widget.initAsync?.call(),
      ]),
    );

    if (initialized) {
      await Control.factory().onReady();
      setState(() {});
    }
  }

  Future<void> _loadTheme() async => _setup.style.setSystemTheme();

  @override
  Widget build(BuildContext context) {
    _setup.context = context;
    _setup.state = _args.get<AppState>();
    _setup.args = _args;

    return Container(
      key: _setup._localKey,
      child: widget.app(
        _setup,
        Builder(builder: (context) {
          _context.value = context;

          return CaseWidget(
            activeCase: _setup.state,
            builders: _states,
            transitionIn: widget.transition,
            transitions: _transitions,
            args: _args,
            soft: false,
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
