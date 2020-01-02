import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

typedef AppBuilder = Widget Function(BuildContext context, Key key, Widget home);

class ControlBase extends StatefulWidget {
  final String defaultLocale;
  final Map<String, String> locales;
  final bool loadLocalization;
  final Map entries;
  final Map<Type, Initializer> initializers;
  final bool debug;
  final Duration loaderDelay;
  final WidgetBuilder loader;
  final Initializer<ControlTheme> theme;
  final Injector injector;
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
  }) : super();

  @override
  State<StatefulWidget> createState() => ControlBaseState();
}

/// Creates State for BaseApp.
/// AppControl and MaterialApp is build here.
/// This State is meant to be used as root.
/// BuildContext from local Builder is used as root context.
class ControlBaseState extends State<ControlBase> implements StateNotifier {
  /// Root GlobalKey is passed into AppControl.
  final _rootKey = GlobalObjectKey('root');

  /// Root BuildContext holder is passed into AppControl.
  final _contextHolder = ContextHolder();

  String _locale;
  LocalizationArgs _localeArgs;
  bool _loading = true;

  WidgetInitializer _rootBuilder;
  WidgetInitializer _loadingBuilder;

  @override
  void notifyState([state]) {
    setState(() {
      final localization = ControlProvider.get<BaseLocalization>();
      if (localization != null) {
        _locale = localization.locale;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.loader != null) {
      _loadingBuilder = WidgetInitializer.of((context) {
        _contextHolder.changeContext(context);

        final loader = widget.loader(context);

        printDebug('build loader');

        return loader;
      });
    } else {
      _loadingBuilder = WidgetInitializer.of((context) {
        _contextHolder.changeContext(context);

        printDebug('build default loader');

        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        );
      });
    }

    _rootBuilder = WidgetInitializer.of((context) {
      _contextHolder.changeContext(context);
      final root = widget.root(context);

      printDebug('build root');

      return root;
    });

    _initControl();
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
        _localeArgs = ControlProvider.get<BaseLocalization>().asArgs();
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

    _locale = ControlProvider.get<BaseLocalization>().defaultLocale;

    _contextHolder.once((context) async {
      if (widget.loadLocalization) {
        _localeArgs = await Control.loadLocalization(context: context);
      }

      if (block != null) {
        await block.finish();
      }

      setState(() {
        _locale = _localeArgs.locale;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppControl.init(
      rootKey: _rootKey,
      contextHolder: _contextHolder,
      rootStateNotifier: this,
      child: widget.app(
          context,
          _rootKey,
          Builder(
            builder: (context) => _buildHomeWidget(context),
          )),
    );
  }

  Widget _buildHomeWidget(BuildContext context) {
    return _loading
        ? _loadingBuilder.getWidget(context, args: {
            'loading': _loading,
            'locale': _locale,
            'debug': widget.debug,
          })
        : _rootBuilder.getWidget(context, args: {
            'loading': _loading,
            'locale': _locale,
            'locale_result': _localeArgs ??
                LocalizationArgs(
                  locale: _locale,
                  source: 'asset',
                  isActive: false,
                  changed: false,
                ),
            'debug': widget.debug,
          });
  }

  @override
  void dispose() {
    super.dispose();
    _contextHolder.dispose();
  }
}
