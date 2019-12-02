import 'package:flutter_control/core.dart';
import 'package:flutter_control/src/base_control.dart';

typedef OnContextChanged = Function(BuildContext context);

class BaseApp extends StatelessWidget {
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

  /// Main - root - [Widget] for whole app.
  /// [AppControl] with [MaterialApp] is build on top of everything.
  /// This Widget helps easily integrate [AppControl] as [InheritedWidget] for descendant widgets.
  /// Currently supports only [MaterialApp].
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
  Widget build(BuildContext context) {
    return ControlBase(
      debug: debug,
      defaultLocale: defaultLocale,
      locales: locales,
      loadLocalization: loadLocalization,
      entries: entries,
      initializers: initializers,
      loaderDelay: loaderDelay,
      loader: loader,
      root: root,
      app: (context, key, home) => MaterialApp(
        key: key,
        home: home,
        title: title,
        theme: theme,
        darkTheme: darkTheme,
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
