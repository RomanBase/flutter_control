part of flutter_control;

/// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
/// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
///
/// [NavigatorStack.single] - Single navigator. Typically used inside other page to show content progress.
/// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
/// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
/// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorControl]s is not required.
///
/// [NavigatorStackControl] is used to navigate between multiple [NavigatorStack]s.
class NavigatorStack extends StatefulWidget {
  final NavigatorControl control;
  final WidgetInitializer initializer;
  final bool overrideNavigation;
  final RouteBuilderFactory? route;

  /// Default constructor
  const NavigatorStack._({
    Key? key,
    required this.control,
    required this.initializer,
    this.overrideNavigation = false,
    this.route,
  }) : super(key: key);

  /// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
  /// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
  ///
  /// Single navigator. Typically used inside other page to show content progress.
  ///
  /// [NavigatorStack]
  static Widget single({
    NavigatorControl? control,
    required WidgetBuilder builder,
    bool overrideNavigation = false,
    RouteBuilderFactory? route,
  }) {
    control ??= NavigatorControl();

    return NavigatorStack._(
      key: ObjectKey(control.menu.key),
      control: control,
      initializer: WidgetInitializer.of(builder),
      overrideNavigation: overrideNavigation,
      route: route,
    );
  }

  /// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
  /// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
  ///
  /// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
  /// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
  /// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorControl]s is not required.
  ///
  /// [NavigatorStackControl] is used to navigate between multiple [NavigatorStack]s.
  ///
  /// [NavigatorStack]
  static Widget group({
    NavigatorStackControl? control,
    required List<NavigatorStack> items,
    StackGroupBuilder? builder,
    bool overrideNavigation = true,
  }) {
    return NavigatorStackGroup(
      control: control ?? NavigatorStackControl(),
      items: items,
      builder: builder,
      overrideNavigation: overrideNavigation,
    );
  }

  /// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
  /// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
  ///
  /// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
  /// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
  /// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorControl]s is not required.
  ///
  /// [NavigatorStackControl] is used to navigate between multiple [NavigatorStack]s.
  ///
  /// [NavigatorStack]
  static Widget menu({
    NavigatorStackControl? control,
    required Map<NavItem, WidgetBuilder> items,
    StackGroupBuilder? builder,
    bool overrideNavigation = true,
    RouteBuilderFactory? route,
  }) {
    final stack = <NavigatorStack>[];

    items.forEach((key, value) => stack.add(NavigatorStack.single(
          control: NavigatorControl(key: key),
          builder: value,
          route: route,
        ) as NavigatorStack));

    return NavigatorStack.group(
      control: control,
      items: stack,
      builder: builder,
      overrideNavigation: overrideNavigation,
    );
  }

  @override
  _NavigatorStackState createState() => _NavigatorStackState();
}

class _NavigatorStackState extends State<NavigatorStack>
    implements StackNavigationHandler {
  late HeroController _heroController;

  GlobalKey<NavigatorState>? _navigatorKey;

  NavigatorState? get navigator => _navigatorKey?.currentState;

  WidgetBuilder get builder =>
      (context) => widget.initializer.getWidget(context);

  @override
  void initState() {
    super.initState();

    widget.control.register(this);

    _heroController = HeroController(
        createRectTween: (begin, end) =>
            MaterialRectArcTween(begin: begin, end: end));

    _updateNavigator();
  }

  @override
  void didUpdateWidget(NavigatorStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateNavigator();
  }

  void _updateNavigator() {
    _navigatorKey ??= GlobalObjectKey<NavigatorState>(this);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator(
      key: _navigatorKey,
      observers: [
        _heroController,
        ...widget.control.menu.observers,
      ],
      onGenerateRoute: (routeSettings) {
        if (widget.route != null) {
          return widget.route!.call(
            builder,
            routeSettings,
          );
        }

        return MaterialPageRoute(
          builder: builder,
          settings: routeSettings,
        );
      },
    );

    if (widget.overrideNavigation) {
      return WillPopScope(
        onWillPop: widget.control.popScope,
        child: navigator,
      );
    }

    return navigator;
  }

  @override
  bool navigateBack() {
    if (navigator != null && navigator!.canPop()) {
      navigator!.pop();
      return true;
    }

    return false;
  }

  @override
  void navigateToRoot() {
    if (navigator != null) {
      navigator!.popUntil((route) => route.isFirst);
    }
  }
}

//########################################################################################
//########################################################################################
//########################################################################################

typedef StackGroupBuilder = Widget Function(
    BuildContext context, int index, List<NavigatorStack> items);

/// [NavigatorStack]
/// [NavigatorControl]
/// [NavigatorStackControl]
class NavigatorStackGroup extends StatefulWidget {
  final NavigatorStackControl control;
  final List<NavigatorStack> items;
  final StackGroupBuilder? builder;
  final bool overrideNavigation;

  NavigatorStackGroup({
    required this.control,
    required this.items,
    this.builder,
    this.overrideNavigation = true,
  }) : super(key: ObjectKey(control)) {
    assert(items.length > 0);
  }

  @override
  _NavigatorStackGroupState createState() => _NavigatorStackGroupState();
}

class _NavigatorStackGroupState extends State<NavigatorStackGroup> {
  NavigatorStackControl get control => widget.control;

  late List<NavigatorStack> _items;

  @override
  void initState() {
    super.initState();

    _items = widget.items;

    control.register(this);

    _initControl();
  }

  void _initControl() {
    control.initControls(
        _items.map((page) => page.control).toList(growable: false));
    control.setPageIndex(control.currentPageIndex);
    control.currentControl?.selected = true;

    if (control.onPagesInitialized != null) {
      control.onPagesInitialized!();
    }
  }

  @override
  void didUpdateWidget(NavigatorStackGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (control != oldWidget.control) {
      _items = widget.items;
      _initControl();
      return;
    }

    final oldMenu = control.menuItems;
    final newMenu =
        widget.items.map((page) => page.control.menu).toList(growable: false);

    final oldMenuHasKeys =
        !oldMenu.any((element) => element.key == NavItem._invalid);
    final newMenuHasKeys =
        !newMenu.any((element) => element.key == NavItem._invalid);

    if (oldMenuHasKeys && newMenuHasKeys) {
      if (oldMenu.length == newMenu.length) {
        bool requestUpdate = false;

        for (int i = 0; i < oldMenu.length; i++) {
          if (oldMenu[i] != newMenu[i]) {
            requestUpdate = true;
            break;
          }
        }

        if (!requestUpdate) {
          return;
        }
      }
    } else {
      printDebug('Stack navigation: re-init.');
      printDebug('Stack navigation: set menu keys to swap items.');

      _items = widget.items;
      _initControl();

      return;
    }

    printDebug('Stack navigation update');

    final menu = List<NavigatorStack>.of(_items);

    menu.removeWhere((item) => !newMenu.contains(item.control.menu));

    widget.items.forEach((item) {
      if (!oldMenu.contains(item.control.menu)) {
        menu.add(item);
      }
    });

    _items.clear();
    newMenu.forEach((item) {
      _items.add(menu.firstWhere((nav) => nav.control.menu == item));
    });

    _initControl();
  }

  @override
  Widget build(BuildContext context) {
    return ControlBuilder<int?>(
      control: widget.control.pageIndex,
      builder: (context, index) {
        final stack = widget.builder?.call(context, index ?? 0, _items) ??
            IndexedStack(
              key: ObjectKey(this),
              index: index,
              children: _items,
            );

        if (widget.overrideNavigation) {
          return WillPopScope(
            onWillPop: widget.control.popScope,
            child: stack,
          );
        }

        return stack;
      },
    );
  }
}
