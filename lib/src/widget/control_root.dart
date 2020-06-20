import 'package:flutter_control/core.dart';

/// Holder of current root context.
final _context = ActionControl.broadcast<BuildContext>();

const _rootKey = GlobalObjectKey<ControlRootState>(ControlRoot);
const _appKey = GlobalObjectKey(AppWidgetBuilder);

typedef AppWidgetBuilder = Widget Function(ControlRootSetup setup);
typedef AppBuilder = Widget Function(Key key, ControlRootSetup setup, Widget child);

class AppState {
  static const init = const AppState();

  static const auth = const _AppStateAuth();

  static const onboarding = const _AppStateOnboarding();

  static const main = const _AppStateMain();

  static const background = const _AppStateBackground();

  const AppState();

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

  //Widget get homeWidget => rootState?._currentWidget;

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

    printDebug('ControlRoot is not in Widget Tree! [ControlScope.baseKey]');
    printDebug('Trying to notify ControlScope.scopeKey ..');

    if (appKey.currentState != null && appKey.currentState.mounted) {
      if (appKey.currentState is StateNotifier) {
        (appKey.currentState as StateNotifier).notifyState(args);
      } else {
        printDebug('Found State is not StateNotifier, Trying to call setState directly..');
        // ignore: invalid_use_of_protected_member
        appKey.currentState.setState(() {});
      }

      return true;
    }

    printDebug('No State to notify found.');

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

  final AppState initScreen;

  final Map<AppState, WidgetBuilder> screens;

  final CrossTransition transitionIn;

  final CrossTransition transitionOut;

  /// Function to typically builds [WidgetsApp] or [MaterialApp] or [CupertinoApp].
  /// Builder provides [Key] and [home] widget.
  final AppBuilder app;

  /// Root [Widget] for whole app.
  ///
  /// [debug] extra debug console prints.
  /// [initLocale] key of default locale. First localization will be used if this value is not set.
  /// [locales] map of supported localizations. Key - locale (en, en_US). Value - asset path.
  /// [loadLocalization] loads localization during [ControlRoot] initialization.
  /// [entries] map of Controllers/Models to init and fill into [ControlFactory].
  /// [initializers] map of dynamic initializers to store in [ControlFactory].
  /// [theme] custom [ControlTheme] config.
  /// [initAsync] extra async function - this function is executed during [ControlFactory.initialize].
  /// [app] builder of App - [WidgetsApp] is expected - [MaterialApp], [CupertinoApp]. Set [AppWidgetBuilder.key] and [AppWidgetBuilder.home] from builder to App Widget.
  const ControlRoot({
    this.debug,
    this.localization,
    this.entries,
    this.initializers,
    this.injector,
    this.routes,
    this.theme,
    this.initAsync,
    this.transitionIn,
    this.transitionOut,
    this.initScreen: AppState.init,
    this.screens: const {},
    @required this.app,
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

  get appStateKey => _args.get<AppState>()?.key;

  BroadcastSubscription _localeSub;

  BroadcastSubscription _themeSub;

  @override
  void initState() {
    super.initState();

    _context.value = context;
    _args[AppState] = widget.initScreen;

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
    _setup.style = ControlTheme.defaultTheme(context, _theme);

    _themeSub = ControlTheme.subscribeChanges((value) {
      setState(() {
        printDebug('theme changed');
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
        _setup.key,
        _setup,
        Builder(builder: (context) {
          _context.value = context;

          return CaseWidget(
            activeCase: _setup.state,
            builders: widget.screens,
            transitionIn: widget.transitionIn,
            transitionOut: widget.transitionOut,
            args: _args,
            soft: false,
            placeholder: (_) => InitLoader.of(
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
