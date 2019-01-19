import 'package:flutter_control/core.dart';

class BaseApp extends StatefulWidget {
  final String title;
  final ThemeData theme;
  final List<LocalizationAsset> locales;
  final BaseController root;
  final Map<String, dynamic> entries;
  final String iso2Locale;

  BaseApp({this.title, this.theme, this.iso2Locale, this.locales, @required this.root, this.entries});

  @override
  State<StatefulWidget> createState() => BaseAppState();
}

class BaseAppState extends State<BaseApp> {
  final rootKey = GlobalKey<State<BaseApp>>();
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

typedef OnContextChanged = Function(BuildContext context);

class ContextHolder {
  BuildContext _context;

  BuildContext get context => _context;

  OnContextChanged onContextChanged;

  ContextHolder({BuildContext context}) {
    _context = context;
  }

  void changeContext(BuildContext context) {
    _context = context;

    if (onContextChanged != null) {
      onContextChanged(context);
    }
  }
}
