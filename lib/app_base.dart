import 'package:flutter_control/core.dart';

typedef OnContextChanged = Function(BuildContext context);

/// Main(root) Widget for whole app.
/// AppControl and root Scaffold is build in State.
/// This Widget helps easily integrate AppControl as InheritedWidget into application.
/// Currently supports only MaterialApp.
class BaseApp extends StatefulWidget {
  final String title;
  final ThemeData theme;
  final List<LocalizationAsset> locales;
  final BaseController root;
  final Map<String, dynamic> entries;
  final String iso2Locale;

  /// Default constructor
  BaseApp({this.title, this.theme, this.iso2Locale, this.locales, @required this.root, this.entries});

  @override
  State<StatefulWidget> createState() => BaseAppState();
}

/// Creates State for BaseApp.
/// AppControl and root Scaffold is build here.
/// This State is used as root GlobalKey.
/// BuildContext from Scaffold is used as root context.
class BaseAppState extends State<BaseApp> {
  /// Root GlobalKey of default Scaffold.
  /// Is passed into AppControl.
  final rootKey = GlobalKey<State<BaseApp>>();

  /// Root BuildContext of default Scaffold.
  /// Is passed into AppControl.
  final contextHolder = ContextHolder();

  @override
  Widget build(BuildContext context) {
    AppLocalization localization;

    if (widget.locales == null) {
      localization = AppLocalization('en', null);
    } else {
      localization = AppLocalization(widget.locales[0].iso2Locale, widget.locales);
    }

    return AppControl(
      rootKey: rootKey,
      contextHolder: contextHolder,
      localization: localization,
      entries: widget.entries,
      child: MaterialApp(
        title: widget.title,
        theme: widget.theme,
        home: Scaffold(
          key: rootKey,
          body: Builder(builder: (ctx) {
            contextHolder.changeContext(ctx);
            localization.changeLocale(widget.iso2Locale ?? (localization.deviceLocale(context)?.languageCode ?? localization.defaultLocale));
            return widget.root.init();
          }),
        ),
      ),
    );
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
  }

  /// Subscribe listener for context changes.
  void subscribe(OnContextChanged onContextChanged, {bool instantNotify: false}) {
    _onContextChanged = onContextChanged;

    if (instantNotify) {
      changeContext(context);
    }
  }

  @override
  void dispose() {
    _onContextChanged = null;
    _context = null;
  }
}
