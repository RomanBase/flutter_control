import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

/// Holder of current root context.
final _context = ActionControl.broadcast<BuildContext>();

const _rootKey = GlobalObjectKey<ControlRootState>(ControlRoot);
const _appKey = GlobalObjectKey(AppBuilder);

typedef AppBuilder = Widget Function(BuildContext context, Key key, Widget home);

class AppState {
  static const none = const AppState();

  static const auth = const AppStateAuth();

  static const onboarding = const AppStateOnboarding();

  static const main = const AppStateMain();

  static const background = const AppStateBackground();

  const AppState();
}

class AppStateAuth extends AppState {
  const AppStateAuth();
}

class AppStateOnboarding extends AppState {
  const AppStateOnboarding();
}

class AppStateBackground extends AppState {
  const AppStateBackground();
}

class AppStateMain extends AppState {
  const AppStateMain();
}

class ControlScope {
  const ControlScope();

  GlobalKey<ControlRootState> get rootKey => _rootKey;

  GlobalKey get appKey => _appKey;

  ControlRoot get rootWidget => _rootKey.currentWidget;

  ControlRootState get rootState => _rootKey.currentState;

  Widget get homeWidget => rootState?._currentWidget;

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

class ControlRoot extends StatefulWidget {
  /// [Control.initControl]
  final bool debug;

  /// [Control.initControl]
  final String defaultLocale;

  /// [Control.initControl]
  final Map<String, String> locales;

  /// extends loader to load default and preferred localization assets.
  final bool loadLocalization;

  /// [Control.initControl]
  final Map entries;

  /// [Control.initControl]
  final Map<Type, Initializer> initializers;

  /// [Control.initControl]
  final Injector injector;

  /// [Control.initControl]
  final List<ControlRoute> routes;

  /// [Control.initControl]
  final Initializer<ControlTheme> theme;

  /// [Control.initControl]
  final Future Function() initAsync;

  /// Custom loader. Check [InitLoader] to provide more robust loader.
  ///
  /// [ControlRootState] is passed as [arg] during Loader initialization..
  /// If custom Loader is used. It's mandatory to notify [ControlRootState] to finish loading - setState with [ControlArgs] and [LoadingStatus].
  /// Easies way is to use [InitLoader.of] or extend [InitLoaderControl].
  ///
  /// Widget will be passed into [AppBuilder] as [home].
  final WidgetBuilder loader;

  /// Entirely disables loader. [root] widget will be initialized on first build pass.
  final bool disableLoader;

  /// Root widget after loader. Widget will be passed into [AppBuilder] as [home].
  /// [ControlArgs] are passed from loader.
  /// It's equal to [ControlScope.homeWidget].
  final ControlWidgetBuilder<ControlArgs> root;

  final CrossTransition transitionIn;

  final CrossTransition transitionOut;

  /// Function to typically builds [WidgetsApp] or [MaterialApp] or [CupertinoApp].
  /// Builder provides [Key] and [home] widget.
  final AppBuilder app;

  /// Root [Widget] for whole app.
  ///
  /// [debug] extra debug console prints.
  /// [defaultLocale] key of default locale. First localization will be used if this value is not set.
  /// [locales] map of supported localizations. Key - locale (en, en_US). Value - asset path.
  /// [loadLocalization] loads localization during [ControlRoot] initialization.
  /// [entries] map of Controllers/Models to init and fill into [ControlFactory].
  /// [initializers] map of dynamic initializers to store in [ControlFactory].
  /// [theme] custom [ControlTheme] builder.
  /// [loader] widget to show during loading and initializing control, localization.
  /// [initAsync] extra async function - this function is executed during [ControlFactory.initialize].
  /// [root] first Widget after loading finished.
  /// [app] builder of App - [WidgetsApp] is expected - [MaterialApp], [CupertinoApp]. Set [AppBuilder.key] and [AppBuilder.home] from builder to App Widget.
  const ControlRoot({
    this.debug,
    this.defaultLocale,
    this.locales,
    this.loadLocalization: true,
    this.entries,
    this.initializers,
    this.injector,
    this.routes,
    this.theme,
    this.loader,
    this.disableLoader: false,
    this.initAsync,
    this.transitionIn,
    this.transitionOut,
    @required this.root,
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
  final transition = TransitionControl();

  final _args = ControlArgs();

  AppState get appState => _args.get<AppState>();

  WidgetInitializer _rootBuilder;
  WidgetInitializer _loadingBuilder;

  BroadcastSubscription _localeSub;

  Widget get _currentWidget {
    bool loader = appState is AppStateOnboarding;

    return loader ? _loadingBuilder?.value : _rootBuilder?.value;
  }

  @override
  void notifyState([state]) {
    if (state is ControlArgs) {
      _args.combine(state);
    }

    if (transition.isInitialized) {
      if (appState is AppStateMain) {
        transition.crossIn();
      } else {
        transition.crossOut();
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _args[AppState] = widget.disableLoader ? AppState.main : AppState.onboarding;

    if (widget.loader != null) {
      _loadingBuilder = WidgetInitializer.of(widget.loader);
    } else {
      _loadingBuilder = WidgetInitializer.of((context) {
        printDebug('build default loader');

        return InitLoader.of(
          builder: (context) => Container(
            color: Theme.of(context).canvasColor,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
          ),
        );
      });
    }

    _rootBuilder = WidgetInitializer.control(widget.root);

    _loadingBuilder.key = GlobalObjectKey(AppState.onboarding);
    _rootBuilder.key = GlobalObjectKey(AppState.main);

    _initControl();
  }

  void _initControl() async {
    final initialized = Control.initControl(
      debug: widget.debug,
      defaultLocale: widget.defaultLocale,
      locales: widget.locales,
      entries: widget.entries,
      initializers: widget.initializers,
      injector: widget.injector,
      routes: widget.routes,
      theme: widget.theme,
      initAsync: () => FutureBlock.wait([
        widget.initAsync != null ? widget.initAsync() : null,
        (widget.loadLocalization && widget.locales != null) ? _loadLocalization() : null,
      ]),
    );

    if (initialized) {
      await Control.factory().onReady();
    }

    _localeSub = BaseLocalization.subscribeChanges((args) {
      if (args.changed) {
        setState(() {});
      }
    });
  }

  Future<void> _loadLocalization() async {
    if (widget.loadLocalization && Control.localization().isDirty) {
      await Control.localization().init();
    }
  }

  @override
  void didUpdateWidget(ControlRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ObjectKey(Control.localization()?.locale ?? '-'),
      child: widget.app(
        context,
        _appKey,
        Builder(
          builder: _buildHome,
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    _context.value = context;

    if (widget.disableLoader) {
      return KeyedSubtree(
        key: _rootBuilder.key,
        child: _rootBuilder.getWidget(context, args: {
          ControlRootState: this,
          ControlArgs: _args,
        }),
      );
    }

    return TransitionHolder(
      control: transition,
      firstWidget: _loadingBuilder,
      secondWidget: _rootBuilder,
      transitionIn: widget.transitionIn,
      transitionOut: widget.transitionOut,
      args: {
        ControlRootState: this,
        ControlArgs: _args,
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _localeSub?.dispose();
    _localeSub = null;
  }
}
