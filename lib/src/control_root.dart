import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

/// Holder of current root context.
final _context = ActionControl.broadcast<BuildContext>();

const _rootKey = GlobalObjectKey<ControlRootState>(ControlRoot);
const _appKey = GlobalObjectKey(AppBuilder);

typedef AppBuilder = Widget Function(BuildContext context, Key key, Widget home);

class ControlScope {
  const ControlScope();

  GlobalKey<ControlRootState> get rootKey => _rootKey;

  GlobalKey get appKey => _appKey;

  ControlRoot rootWidget() => _rootKey.currentWidget;

  ControlRootState rootState() => _rootKey.currentState;

  /// Returns current context from [contextHolder]
  BuildContext get rootContext => _context.value;

  /// Sets new root context to [contextHolder]
  set rootContext(BuildContext context) => _context.value = context;

  ActionControlStream get rootContextSub => _context.sub;

  bool notifyControlState([dynamic state]) {
    if (rootKey.currentState != null && rootKey.currentState.mounted) {
      rootKey.currentState.notifyState(state);

      return true;
    }

    printDebug('ControlBase is not in Widget Tree! (ControlScope.baseKey)');
    printDebug('Trying to notify ControlScope.scopeKey ..');

    if (appKey.currentState != null && appKey.currentState.mounted) {
      if (appKey.currentState is StateNotifier) {
        (appKey.currentState as StateNotifier).notifyState(state);
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
}

class ControlRoot extends StatefulWidget {
  final bool debug;
  final String defaultLocale;
  final Map<String, String> locales;
  final bool loadLocalization;
  final Map entries;
  final Map<Type, Initializer> initializers;
  final Injector injector;
  final List<ControlRoute> routes;
  final Initializer<ControlTheme> theme;
  final WidgetBuilder loader;
  final bool disableLoader;
  final ControlWidgetBuilder<ControlArgs> root;
  final AppBuilder app;
  final VoidCallback onInit;

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
  /// [root] first Widget after loading finished.
  /// [app] builder of App - [WidgetsApp] is expected - [MaterialApp], [CupertinoApp]. Set [AppBuilder.key] and [AppBuilder.home] from builder to App Widget.
  const ControlRoot({
    this.debug: false,
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
    @required this.root,
    @required this.app,
    this.onInit,
  }) : super(key: _rootKey);

  @override
  State<StatefulWidget> createState() => ControlRootState();
}

/// Creates State for BaseApp.
/// AppControl and MaterialApp is build here.
/// This State is meant to be used as root.
/// BuildContext from local Builder is used as root context.
class ControlRootState extends State<ControlRoot> implements StateNotifier {
  final _args = ControlArgs({LoadingStatus: LoadingStatus.progress});

  bool _loadingLocale = true;

  LoadingStatus get loadingStatus => _args[LoadingStatus];

  bool get loading => _loadingLocale || loadingStatus != LoadingStatus.done;

  WidgetInitializer _rootBuilder;
  WidgetInitializer _loadingBuilder;

  BroadcastSubscription _localeSub;

  @override
  void notifyState([state]) {
    setState(() {
      if (state is ControlArgs) {
        _args.combine(state);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    Control.factory().swap<ControlRoot>(value: widget);

    if (widget.disableLoader) {
      _loadingLocale = false;
      _args[LoadingStatus] = LoadingStatus.done;
    }

    if (widget.loader != null) {
      _loadingBuilder = WidgetInitializer.of(widget.loader);
    } else {
      _args[LoadingStatus] = LoadingStatus.done;
      _loadingBuilder = WidgetInitializer.of((context) {
        printDebug('build default loader');

        return Container(
          color: Theme.of(context).canvasColor,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
        );
      });
    }

    _rootBuilder = WidgetInitializer.control(widget.root);

    _localeSub = BaseLocalization.subscribeChanges((args) {
      if (args.changed && Control.localization().isSystemLocaleActive(_context.value)) {
        setState(() {
          _loadingLocale = false;
        });
      }
    });

    _initControl();
  }

  void _initControl() async {
    if (!Control.isInitialized) {
      Control.initControl(
        debug: widget.debug,
        defaultLocale: widget.defaultLocale,
        locales: widget.locales ?? {'en': null},
        entries: widget.entries ?? {},
        initializers: widget.initializers ?? {},
        injector: widget.injector,
        routes: widget.routes,
        theme: widget.theme,
      );
    }

    if (widget.loadLocalization && Control.localization().isValid && !Control.localization().isActive) {
      _context.once((context) async => await Control.localization().init(context: context));
    } else {
      setState(() {
        _loadingLocale = false;
      });
    }
  }

  @override
  void didUpdateWidget(ControlRoot oldWidget) {
    super.didUpdateWidget(oldWidget);

    Control.factory().swap<ControlRoot>(value: widget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ObjectKey(Control.localization()?.locale ?? '-'),
      child: widget.app(
        context,
        _appKey,
        Builder(
          builder: (context) => _buildHome(context),
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    _context.value = context;

    return loading
        ? _loadingBuilder.getWidget(
            context,
            args: {
              ControlRootState: this,
              ControlArgs: _args,
            },
          )
        : _rootBuilder.getWidget(
            context,
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

class EmptyWidget extends Widget {
  @override
  Element createElement() => EmptyElement(this);
}

class EmptyElement extends Element {
  EmptyElement(Widget widget) : super(widget);

  @override
  void forgetChild(Element child) {
    printDebug('empty element: forget');
  }

  @override
  void performRebuild() {
    printDebug('empty element: rebuild');
  }
}
