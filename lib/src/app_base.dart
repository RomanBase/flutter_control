import 'package:flutter_control/core.dart';

typedef OnContextChanged = Function(BuildContext context);

/// Main - root - [Widget] for whole app.
/// [AppControl] is build on top of everything.
/// This Widget helps easily integrate [AppControl] as [InheritedWidget] for descendant widgets.
/// Currently supports only MaterialApp.
class BaseApp extends StatefulWidget {
  final String title;
  final ThemeData theme;
  final ThemeData darkTheme;
  final String defaultLocale;
  final Map<String, String> locales;
  final bool loadLocalization;
  final Map<String, dynamic> entries;
  final Map<Type, Initializer> initializers;
  final bool debug;
  final Duration loaderDelay;
  final WidgetBuilder loader;
  final WidgetBuilder root;

  /// Default constructor
  const BaseApp({
    @required this.title,
    this.theme,
    this.darkTheme,
    this.defaultLocale,
    this.locales,
    this.loadLocalization: true,
    this.entries,
    this.initializers,
    this.debug,
    this.loaderDelay,
    this.loader,
    @required this.root,
  });

  @override
  State<StatefulWidget> createState() => BaseAppState();
}

/// Creates State for BaseApp.
/// AppControl and root Scaffold is build here.
/// This State is used as root GlobalKey.
/// BuildContext from Scaffold is used as root context.
/// Structure: AppControl -> MaterialApp -> Scaffold -> Your Content (root - BaseController).
class BaseAppState extends State<BaseApp> implements StateNotifier {
  /// Root GlobalKey of default Scaffold.
  /// Is passed into AppControl.
  final rootKey = GlobalKey<State<BaseApp>>();

  /// Root BuildContext of default Scaffold.
  /// Is passed into AppControl.
  final contextHolder = ContextHolder();

  String defaultLocale;
  WidgetInitializer _rootBuilder;

  bool _loading = true;

  @override
  void notifyState([state]) {
    setState(() {
      final localization = ControlProvider.of<BaseLocalization>(ControlKey.localization);
      if (localization != null) {
        defaultLocale = localization.locale;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _initControl(widget.locales, widget.entries, widget.initializers);

    _rootBuilder = WidgetInitializer.of((context) {
      contextHolder.changeContext(context);
      final root = widget.root(context);

      if (root is Initializable) {
        (root as Initializable).init({});
      }

      debugPrint('build root');

      return root;
    });
  }

  void _initControl(Map<String, String> locales, Map<String, dynamic> entries, Map<Type, Initializer> initializers) {
    DelayBlock block;
    if (widget.loaderDelay != null) {
      block = DelayBlock(widget.loaderDelay);
    }

    final factory = ControlFactory.of(this);

    if (factory.isInitialized) {
      return; //TODO: solve this for hot reload
    }

    if (entries == null) {
      entries = Map<String, dynamic>();
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
      preloadDefaultLocalization: widget.loadLocalization,
    );

    factory.initialize(items: entries, initializers: initializers);

    final localization = ControlProvider.of<BaseLocalization>(ControlKey.localization);
    localization.debug = widget.debug ?? debugMode;

    defaultLocale = localization.defaultLocale;

    contextHolder.once((context) async {
      if (widget.loadLocalization) {
        await localization.changeToSystemLocale(context);
      }

      if (block != null) {
        await block.finish();
      }

      setState(() {
        _loading = false;
        defaultLocale = localization.locale;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppControl(
      rootKey: rootKey,
      contextHolder: contextHolder,
      locale: defaultLocale,
      rootState: this,
      child: MaterialApp(
        key: rootKey,
        title: widget.title,
        theme: widget.theme,
        darkTheme: widget.darkTheme,
        home: _loading
            ? Builder(builder: (context) {
                contextHolder.changeContext(context);
                return widget.loader != null ? widget.loader(context) : Center(child: CircularProgressIndicator());
              })
            : Builder(builder: (context) {
                // root context is then changed via _rootBuilder
                return _rootBuilder.getWidget(context);
              }),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    contextHolder.dispose();
  }
}

/// Holds BuildContext and notifies if changed.
class ContextHolder implements Disposable {
  /// Current context.
  /// Can be changed later.
  BuildContext _context;

  /// Returns current context.
  BuildContext get context => _context;

  /// On context changed listener.
  OnContextChanged _onContextChanged;

  /// Notify just once on context changed listener.
  OnContextChanged _onContextChangedOnce;

  /// Initializes ContextHolder with default context.
  ContextHolder({BuildContext context}) {
    _context = context;
  }

  /// Changes current context.
  void changeContext(BuildContext context) {
    _context = context;

    if (_onContextChanged != null) {
      _onContextChanged(context);
    }

    if (_onContextChangedOnce != null) {
      _onContextChangedOnce(context);
      _onContextChangedOnce = null;
    }
  }

  /// Subscribe listener for context changes.
  void subscribe(OnContextChanged onContextChanged, {bool instantNotify: false}) {
    _onContextChanged = onContextChanged;

    if (instantNotify && context != null) {
      changeContext(context);
    }
  }

  /// Subscribe listener just of one context change.
  void once(OnContextChanged onContextChanged) {
    if (context != null) {
      onContextChanged(context);
    } else {
      _onContextChangedOnce = onContextChanged;
    }
  }

  @override
  void dispose() {
    _onContextChanged = null;
    _context = null;
  }
}
