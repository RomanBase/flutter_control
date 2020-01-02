import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

/// Holder of current root context.
final _context = ActionControl<BuildContext>.broadcast();

const _baseKey = GlobalObjectKey('base');

typedef AppBuilder = Widget Function(BuildContext context, Widget home);

class ControlBase extends StatefulWidget {
  static ControlBase of(BuildContext context) {
    ControlBase base;

    if (context != null) {
      base = context.findAncestorWidgetOfExactType<ControlBase>();
    }

    return base ?? ControlProvider.get<ControlBase>();
  }

  /// Returns current context from [contextHolder]
  BuildContext get rootContext => _context.value;

  /// Sets new root context to [contextHolder]
  set rootContext(BuildContext context) => _context.value = context;

  final bool debug;
  final String defaultLocale;
  final Map<String, String> locales;
  final bool loadLocalization;
  final Map entries;
  final Map<Type, Initializer> initializers;
  final Injector injector;
  final Initializer<ControlTheme> theme;
  final Duration loaderDelay;
  final WidgetBuilder loader;
  final WidgetBuilder root;
  final AppBuilder app;
  final VoidCallback onInit;

  /// Root [Widget] for whole app.
  ///
  /// [debug] extra debug console prints.
  /// [defaultLocale] key of default locale. First localization will be used if this value is not set.
  /// [locales] map of supported localizations. Key - locale (en, en_US). Value - asset path.
  /// [loadLocalization] loads localization during [ControlBase] initialization.
  /// [entries] map of Controllers/Models to init and fill into [ControlFactory].
  /// [initializers] map of dynamic initializers to store in [ControlFactory].
  /// [theme] custom [ControlTheme] builder.
  /// [loaderDelay] extra (minimum) loader time.
  /// [loader] widget to show during loading and initializing control, localization.
  /// [root] first Widget after loading finished.
  /// [app] builder of App - [WidgetsApp] is expected - [MaterialApp], [CupertinoApp]. Set [AppBuilder.key] and [AppBuilder.home] from builder to App Widget.
  const ControlBase({
    this.debug: false,
    this.defaultLocale,
    this.locales,
    this.loadLocalization: true,
    this.entries,
    this.initializers,
    this.injector,
    this.theme,
    this.loaderDelay,
    this.loader,
    @required this.root,
    @required this.app,
    this.onInit,
  }) : super(key: _baseKey);

  @override
  State<StatefulWidget> createState() => ControlBaseState();

  ActionSubscription<BuildContext> subscribeContextChanges(ValueCallback<BuildContext> callback) => _context.subscribe(callback);

  ActionSubscription<BuildContext> subscribeNextContextChange(ValueCallback<BuildContext> callback) => _context.once(callback);

  void notifyControlState() {
    (_baseKey.currentState as StateNotifier)?.notifyState();
  }
}

/// Creates State for BaseApp.
/// AppControl and MaterialApp is build here.
/// This State is meant to be used as root.
/// BuildContext from local Builder is used as root context.
class ControlBaseState extends State<ControlBase> implements StateNotifier {
  bool _loading = true;

  WidgetInitializer _rootBuilder;
  WidgetInitializer _loadingBuilder;

  @override
  void notifyState([state]) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    ControlProvider.set<ControlBase>(value: widget);

    if (widget.loader != null) {
      _loadingBuilder = WidgetInitializer.of((context) {
        widget.rootContext = context;
        printDebug('build loader');

        return widget.loader(context);
      });
    } else {
      _loadingBuilder = WidgetInitializer.of((context) {
        widget.rootContext = context;
        printDebug('build default loader');

        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        );
      });
    }

    _rootBuilder = WidgetInitializer.of((context) {
      widget.rootContext = context;
      printDebug('build root');

      return widget.root(context);
    });

    _initControl();
  }

  @override
  Widget build(BuildContext context) {
    printDebug('build base');

    return ControlScope(
      locale: ControlProvider.get<BaseLocalization>().locale,
      child: widget.app(
        context,
        Builder(
          builder: (context) => _buildHomeWidget(context),
        ),
      ),
    );
  }

  Widget _buildHomeWidget(BuildContext context) {
    return _loading
        ? _loadingBuilder.getWidget(context, args: {
            'loading': _loading,
            'debug': widget.debug,
          })
        : _rootBuilder.getWidget(context, args: {
            'loading': _loading,
            'debug': widget.debug,
          });
  }

  void _initControl() async {
    DelayBlock block;
    if (widget.loaderDelay != null) {
      block = DelayBlock(widget.loaderDelay);
    }

    if (Control.isInitialized) {
      if (block != null) {
        await block.finish();
      }

      setState(() {
        _loading = false;
      });

      return;
    }

    Control.init(
      debug: widget.debug,
      defaultLocale: widget.defaultLocale,
      locales: widget.locales ?? {'en': null},
      entries: widget.entries ?? {},
      initializers: widget.initializers ?? {},
      theme: widget.theme,
      injector: widget.injector,
    );

    widget.subscribeNextContextChange((context) async {
      if (widget.loadLocalization) {
        await Control.loadLocalization(context: context);
      }

      if (block != null) {
        await block.finish();
      }

      setState(() {
        _loading = false;
      });
    });
  }
}

class ControlScope extends InheritedWidget {
  final String locale;

  const ControlScope({Widget child, this.locale}) : super(key: const ObjectKey('scope'), child: child);

  @override
  bool updateShouldNotify(ControlScope oldWidget) {
    printDebug('should notify - $locale : ${locale != oldWidget.locale}');
    return locale != oldWidget.locale;
  }
}
