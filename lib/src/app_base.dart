import 'package:flutter_control/core.dart';

typedef OnContextChanged = Function(BuildContext context);

/// Main - root - [Widget] for whole app.
/// [AppControl] is build on top of everything.
/// This Widget helps easily integrate [AppControl] as [InheritedWidget] for descendant widgets.
/// Currently supports only MaterialApp.
class BaseApp extends StatefulWidget {
  final String title;
  final ThemeData theme;
  final Map<String, String> locales;
  final WidgetBuilder root;
  final WidgetBuilder loader;
  final Map<String, dynamic> entries;
  final Map<Type, Initializer> initializers;
  final String defaultLocale;
  final bool debug;
  final Duration loaderDelay;

  /// Default constructor
  const BaseApp({
    @required this.title,
    this.theme,
    this.defaultLocale,
    this.locales,
    @required this.root,
    this.loader,
    this.entries,
    this.initializers,
    this.debug,
    this.loaderDelay,
  });

  @override
  State<StatefulWidget> createState() => BaseAppState();
}

/// Creates State for BaseApp.
/// AppControl and root Scaffold is build here.
/// This State is used as root GlobalKey.
/// BuildContext from Scaffold is used as root context.
/// Structure: AppControl -> MaterialApp -> Scaffold -> Your Content (root - BaseController).
class BaseAppState extends State<BaseApp> {
  /// Root GlobalKey of default Scaffold.
  /// Is passed into AppControl.
  final rootKey = GlobalKey<State<BaseApp>>();

  /// Root BuildContext of default Scaffold.
  /// Is passed into AppControl.
  final contextHolder = ContextHolder();

  WidgetInitializer _rootBuilder;

  bool _loading = true;

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

    entries[ControlKey.control] = this;
    entries[ControlKey.preferences] = BasePrefs();
    entries[ControlKey.localization] = BaseLocalization(widget.defaultLocale ?? localizationAssets[0].iso2Locale, localizationAssets);

    factory.initialize(items: entries, initializers: initializers);

    final localization = ControlProvider.of<BaseLocalization>(ControlKey.localization);
    localization.debug = widget.debug ?? debugMode;

    contextHolder.once((context) async {
      await localization.changeToSystemLocale(context);

      if (widget.loaderDelay != null) {
        await Future.delayed(widget.loaderDelay);
      }

      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppControl(
      rootKey: rootKey,
      contextHolder: contextHolder,
      debug: widget.debug ?? debugMode,
      child: MaterialApp(
        key: rootKey,
        title: widget.title,
        theme: widget.theme,
        home: _loading
            ? Builder(
                builder: (context) {
                  contextHolder.changeContext(context);
                  return widget.loader != null ? widget.loader(context) : Center(child: CircularProgressIndicator());
                },
              )
            : Builder(
                builder: (context) => _rootBuilder.getWidget(context),
              ),
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
