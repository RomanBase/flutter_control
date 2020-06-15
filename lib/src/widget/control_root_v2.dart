import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

const _rootKey = GlobalObjectKey<ControlRootState>(ControlRoot);
const _appKey = GlobalObjectKey(AppBuilder);

class ControlRootV2 extends StatefulWidget {
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

  final AppState defaultScreen;

  final Map<AppState, WidgetBuilder> screens;

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
  const ControlRootV2({
    this.debug,
    this.defaultLocale,
    this.locales,
    this.loadLocalization: true,
    this.entries,
    this.initializers,
    this.injector,
    this.routes,
    this.theme,
    this.initAsync,
    this.transitionIn,
    this.transitionOut,
    this.defaultScreen: AppState.init,
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
class ControlRootState extends State<ControlRootV2> implements StateNotifier {
  final _args = ControlArgs();

  AppState get appState => _args.get<AppState>();

  Map<Type, WidgetBuilder> states;

  BroadcastSubscription _localeSub;

  @override
  void notifyState([state]) {
    if (state is ControlArgs) {
      _args.combine(state);
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _args[AppState] = widget.defaultScreen;

    states = widget.screens.map((key, value) => MapEntry(key.key, value));

    if (widget.defaultScreen == AppState.init && !states.containsKey(AppState.init.key)) {
      states[AppState.init.key] = (context) => InitLoader.of(
            builder: (context) => Container(
              color: Theme.of(context).canvasColor,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              ),
            ),
          );
    }

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
  Widget build(BuildContext context) {
    return Container(
      key: ObjectKey(Control.localization()?.locale ?? '-'),
      child: widget.app(
        context,
        _appKey,
        Builder(
          builder: (BuildContext context) {
            //_context.value = context;

            return CaseWidget(
              activeCase: appState,
              builders: states,
              transitionIn: widget.transitionIn,
              transitionOut: widget.transitionOut,
              args: _args,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _localeSub?.dispose();
    _localeSub = null;
  }
}
