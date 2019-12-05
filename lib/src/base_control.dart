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
  final WidgetBuilder root;
  final AppBuilder app;

  /// Main - root - [Widget] for whole app.
  /// [AppControl] with [MaterialApp] is build on top of everything.
  /// This Widget helps easily integrate [AppControl] as [InheritedWidget] for descendant widgets.
  /// Currently supports only [MaterialApp].
  const ControlBase({
    this.defaultLocale,
    this.locales,
    this.loadLocalization: true,
    this.entries,
    this.initializers,
    this.debug,
    this.loaderDelay,
    this.loader,
    @required this.root,
    @required this.app,
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
  bool _loading = true;
  WidgetInitializer _rootBuilder;

  @override
  void notifyState([state]) {
    setState(() {
      final localization = ControlProvider.get<BaseLocalization>(ControlKey.localization);
      if (localization != null) {
        _locale = localization.locale;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _initControl(widget.locales, widget.entries, widget.initializers);

    _rootBuilder = WidgetInitializer.of((context) {
      _contextHolder.changeContext(context);
      final root = widget.root(context);

      if (root is Initializable) {
        (root as Initializable).init({});
      }

      debugPrint('build root');

      return root;
    });
  }

  void _initControl(Map<String, String> locales, Map entries, Map<Type, Initializer> initializers) {
    DelayBlock block;
    if (widget.loaderDelay != null) {
      block = DelayBlock(widget.loaderDelay);
    }

    final factory = ControlFactory.of(this);

    if (factory.isInitialized) {
      return; //TODO: solve this for hot reload
    }

    if (entries == null) {
      entries = Map();
    }

    if (locales == null || locales.isEmpty) {
      locales = Map<String, String>();
      locales['en'] = null;
    }

    final localizationAssets = List<LocalizationAsset>();
    locales.forEach((key, value) => localizationAssets.add(LocalizationAsset(key, value)));

    entries[ControlKey.preferences] = BasePrefs();
    entries[ControlKey.localization] = BaseLocalization(
      widget.defaultLocale ?? localizationAssets[0].iso2Locale,
      localizationAssets,
    );

    factory.initialize(items: entries, initializers: initializers);

    final localization = ControlProvider.get<BaseLocalization>(ControlKey.localization);
    localization.debug = widget.debug ?? debugMode;

    _locale = localization.defaultLocale;

    _contextHolder.once((context) async {
      if (widget.loadLocalization) {
        await localization.loadDefaultLocalization();
        await localization.changeToSystemLocale(context);
      }

      if (block != null) {
        await block.finish();
      }

      setState(() {
        _loading = false;
        _locale = localization.locale;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppControl.init(
      rootKey: _rootKey,
      contextHolder: _contextHolder,
      rootStateNotifier: this,
      child: widget.app(context, _rootKey, _buildHomeWidget()),
    );
  }

  Widget _buildHomeWidget() {
    return _loading
        ? Builder(builder: (context) {
            _contextHolder.changeContext(context);
            return widget.loader != null ? widget.loader(context) : Center(child: CircularProgressIndicator());
          })
        : Builder(builder: (context) {
            // root context is then changed via _rootBuilder
            return _rootBuilder.getWidget(context);
          });
  }

  @override
  void dispose() {
    super.dispose();
    _contextHolder.dispose();
  }
}
