import 'dart:async';

import 'package:flutter_control/core.dart';

typedef MenuCallback<T> = T Function(bool selected);

class MenuItem {
  final Object key;
  final MenuCallback<dynamic> iconBuilder;
  final MenuCallback<String> titleBuilder;
  final Object data;
  final bool selected;
  final ValueGetter<bool> onSelected;

  dynamic get icon => iconBuilder != null ? iconBuilder(selected) : null;

  String get title => titleBuilder != null ? titleBuilder(selected) : null;

  const MenuItem({
    this.key,
    this.iconBuilder,
    this.titleBuilder,
    this.data,
    this.selected: false,
    this.onSelected,
  });

  MenuItem copyWith({
    Object key,
    Object data,
    bool selected,
  }) =>
      MenuItem(
        key: key ?? this.key,
        iconBuilder: iconBuilder ?? this.iconBuilder,
        titleBuilder: titleBuilder ?? this.titleBuilder,
        data: data ?? this.data,
        selected: selected ?? this.selected,
      );

  @override
  bool operator ==(other) {
    return other is MenuItem && other.key == key;
  }

  @override
  int get hashCode => super.hashCode;
}

/// Helper interface to notify [State]
abstract class _StackNavigator {
  BuildContext get navigatorContext;

  /// Navigate back withing [NavigatorStack]
  /// Returns [true] if navigation is handled by Controller.
  bool navigateBack();

  /// Navigate to first Widget of [NavigatorStack]
  void navigateToRoot();
}

/// Controller for [NavigatorStack]
///
/// [NavigatorStackController]
/// [WillPopScope]
/// [RouteHandler]  [RouteControlProvider]
class NavigatorController extends BaseController {
  /// Data for menu item.
  /// Mostly used in combination with [NavigatorStackController]
  MenuItem menu = MenuItem();

  /// Implementation of StackNavigator.
  _StackNavigator _navigator;

  /// Check if navigator is set during subscribe (State init) phase.
  bool get isNavigatorAvailable => _navigator != null;

  /// Data for menu item.
  /// Returns if this controller is selected.
  /// Mostly used in combination with [NavigatorStackController]
  bool get selected => menu.selected;

  /// Data for menu item.
  /// Sets selection for this controller.
  /// Mostly used in combination with [NavigatorStackController]
  set selected(value) {
    menu = menu.copyWith(selected: value);
    if (onSelectionChanged != null) {
      onSelectionChanged(value);
    }
  }

  /// Notifies about selection changes.
  ValueCallback<bool> onSelectionChanged;

  /// Default constructor
  NavigatorController({this.menu});

  @override
  void subscribe(object) {
    super.subscribe(object);

    if (object is _StackNavigator) {
      _navigator = object;
    }
  }

  bool navigateBack() => _navigator != null ? _navigator.navigateBack() : false;

  void navigateToRoot() => _navigator?.navigateToRoot();

  /// Helper function for [WillPopScope].
  /// Returns negation of [navigateBack] as Future.
  Future<bool> popScope() async => !navigateBack();
}

/// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
/// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
///
/// [NavigatorStack.single] - Single navigator. Typically used inside other page to show content progress.
/// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
/// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
/// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorController]s is not required.
///
/// [NavigatorStackController] is used to navigate between multiple [NavigatorStack]s.
///
/// [RouteHandler] [RouteControlProvider]
class NavigatorStack extends StatefulWidget {
  final NavigatorController controller;
  final WidgetInitializer initializer;
  final bool overrideNavigation;

  /// Default constructor
  const NavigatorStack._({
    Key key,
    @required this.controller,
    @required this.initializer,
    this.overrideNavigation: false,
  }) : super(key: key);

  /// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
  /// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
  ///
  /// Single navigator. Typically used inside other page to show content progress.
  ///
  /// [NavigatorStack]
  static Widget single({
    NavigatorController control,
    @required WidgetBuilder builder,
    bool overrideNavigation: false,
  }) {
    control ??= NavigatorController();

    return NavigatorStack._(
      key: ObjectKey(control),
      controller: control,
      initializer: WidgetInitializer.of(builder),
      overrideNavigation: overrideNavigation,
    );
  }

  /// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
  /// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
  ///
  /// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
  /// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
  /// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorController]s is not required.
  ///
  /// [NavigatorStackController] is used to navigate between multiple [NavigatorStack]s.
  ///
  /// [NavigatorStack]
  static Widget group({
    NavigatorStackController controller,
    int initialIndex,
    @required List<NavigatorStack> items,
    bool overrideNavigation: true,
  }) {
    return NavigatorStackGroup(
      control: controller ?? NavigatorStackController(),
      initialIndex: initialIndex,
      items: items,
      overrideNavigation: overrideNavigation,
    );
  }

  /// Creates new [Navigator] and all underling Widgets will be pushed to this stack.
  /// With [overrideNavigation] Widget will create [WillPopScope] and handles back button.
  ///
  /// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
  /// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
  /// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorController]s is not required.
  ///
  /// [NavigatorStackController] is used to navigate between multiple [NavigatorStack]s.
  ///
  /// [NavigatorStack]
  static Widget menu({
    NavigatorStackController controller,
    int initialIndex,
    @required Map<MenuItem, WidgetBuilder> items,
    bool overrideNavigation: true,
  }) {
    final stack = List<NavigatorStack>();

    items.forEach((key, value) => stack.add(NavigatorStack.single(
          control: NavigatorController(menu: key),
          builder: value,
        )));

    return NavigatorStack.group(
      controller: controller,
      initialIndex: initialIndex,
      items: stack,
      overrideNavigation: overrideNavigation,
    );
  }

  @override
  _NavigatorStackState createState() => _NavigatorStackState();
}

class _NavigatorStackState extends State<NavigatorStack> implements _StackNavigator {
  BuildContext _navigatorContext;

  @override
  BuildContext get navigatorContext => _navigatorContext;

  GlobalKey<NavigatorState> _navigatorKey;

  NavigatorState get navigator => _navigatorKey?.currentState;

  @override
  void initState() {
    super.initState();

    widget.controller.subscribe(this);

    _updateNavigator();
  }

  @override
  void didUpdateWidget(NavigatorStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    printDebug('update nav');
    _updateNavigator();
  }

  void _updateNavigator() {
    _navigatorKey ??= GlobalObjectKey<NavigatorState>(this);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator(
      key: _navigatorKey,
      onGenerateRoute: (routeSettings) {
        return _InstantRoute(builder: (context) {
          _navigatorContext = context;
          return widget.initializer.getWidget(context) ?? Container();
        });
      },
    );

    if (widget.overrideNavigation) {
      return WillPopScope(
        onWillPop: widget.controller.popScope,
        child: navigator,
      );
    }

    return navigator;
  }

  @override
  bool navigateBack() {
    if (navigator != null && navigator.canPop()) {
      return navigator.pop();
    }

    return false;
  }

  @override
  void navigateToRoot() {
    if (navigator != null) {
      navigator.popUntil((route) => route.isFirst);
    }
  }
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Controller for:
/// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
/// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
/// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorController]s is not required.
///
/// [NavigatorStack]
class NavigatorStackController extends BaseController {
  /// List of Controllers set in Widget construct phase.
  List<NavigatorController> _items;

  /// List of Controllers set in Widget construct phase.
  List<NavigatorController> get items => _items;

  /// List of MenuItems set in Widget construct phase.
  List<MenuItem> get menuItems => _items.map((item) => item.menu).toList(growable: false);

  /// Returns current controller - based on [currentPageIndex].
  NavigatorController get currentControl => _items[currentPageIndex];

  MenuItem get currentMenu => currentControl.menu;

  /// Notifies about page changes.
  /// Can be used with [ActionBuilder] to rebuild menu or highlight active widget.
  ///
  /// Use [setPageIndex] to change Page.
  final _pageIndex = ActionControl<int>.broadcast(0);

  /// Returns current page index.
  /// Use [setPageIndex] to change active controller.
  /// Use [pageIndex] to be notified about changes.
  int get currentPageIndex => _pageIndex.value;

  /// Subscription to listen about page index changes.
  ActionControlSub<int> get pageIndex => _pageIndex.sub;

  bool reloadOnReselect = true;

  VoidCallback onPagesInitialized;

  int _initialIndex;

  NavigatorStackController({int initialPageIndex, this.reloadOnReselect: true}) {
    _initialIndex = initialPageIndex;
    _pageIndex.value = _initialIndex ?? 0;
  }

  /// Sets page index and notifies [pageIndex]
  /// Given index is clamped between valid indexes [items.length]
  /// Notifies [State] to switch Pages.
  void setPageIndex(int index, {bool notify: true}) {
    index = index.clamp(0, _items.length - 1);

    if (currentPageIndex == index) {
      if (items[index].menu?.onSelected != null) {
        if (items[index].menu.onSelected()) {
          return;
        }
      }

      if (reloadOnReselect) {
        currentControl.reload();
      }

      return;
    }

    currentControl.selected = false;

    if (items[index].menu?.onSelected != null) {
      if (items[index].menu.onSelected()) {
        return;
      }
    }

    currentControl.selected = true;

    if (notify) {
      _pageIndex.setValue(index);
    } else {
      _pageIndex.pushValue(index);
    }
  }

  void setMenuItem(MenuItem item) => setPageIndex(menuItems.indexOf(item));

  void setInitialPage() => setPageIndex(_initialIndex ?? 0);

  /// Navigates back withing active [NavigatorStack] or sets page index to 0.
  /// Returns [true] if navigation is handled by Controller.
  bool navigateBack() {
    final rootIndex = _initialIndex ?? 0;

    if (currentPageIndex != rootIndex) {
      if (!currentControl.navigateBack()) {
        setPageIndex(rootIndex);
      }

      return true;
    }

    return currentControl.navigateBack();
  }

  /// Helper function for [WillPopScope].
  /// Returns negation of [navigateBack] as Future.
  Future<bool> popScope() async => !navigateBack();

  @override
  void softDispose() {
    super.softDispose();

    setInitialPage();
  }

  @override
  void dispose() {
    super.dispose();

    _items?.clear();
    _pageIndex.dispose();
  }
}

//TODO: custom animation in/out
/// [NavigatorStack]
/// [NavigatorController]
/// [NavigatorStackController]
class NavigatorStackGroup extends StatefulWidget {
  final NavigatorStackController control;
  final List<NavigatorStack> items;
  final int initialIndex;
  final bool overrideNavigation;

  NavigatorStackGroup({
    @required this.control,
    @required this.items,
    this.initialIndex,
    this.overrideNavigation: true,
  }) : super(key: ObjectKey(control)) {
    assert(items.length > 0);
  }

  @override
  _NavigatorStackGroupState createState() => _NavigatorStackGroupState();
}

class _NavigatorStackGroupState extends State<NavigatorStackGroup> {
  NavigatorStackController get control => widget.control;
  List<NavigatorStack> _items;

  @override
  void initState() {
    super.initState();

    if (_items == null) {
      _items = widget.items;
    }

    control.subscribe(this);
    _initControl();
  }

  void _initControl() {
    control._items = _items.map((page) => page.controller).toList(growable: false);

    if (control._initialIndex == null && widget.initialIndex != null) {
      control._initialIndex = widget.initialIndex;
      control._pageIndex.pushValue(control._initialIndex);
    }

    control.setPageIndex(control.currentPageIndex, notify: false);

    if (control.onPagesInitialized != null) {
      control.onPagesInitialized();
    }
  }

  @override
  void didUpdateWidget(NavigatorStackGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialIndex != oldWidget.initialIndex) {
      control._initialIndex = null;
    }

    if (control != oldWidget.control) {
      _items = widget.items;
      _initControl();
      return;
    }

    final oldMenu = control.menuItems;
    final newMenu = widget.items.map((page) => page.controller.menu).toList(growable: false);

    final oldMenuHasKeys = oldMenu.firstWhere((item) => item.key == null, orElse: () => null) == null;
    final newMenuHasKeys = newMenu.firstWhere((item) => item.key == null, orElse: () => null) == null;

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

    menu.removeWhere((item) => !newMenu.contains(item.controller.menu));

    widget.items.forEach((item) {
      if (!oldMenu.contains(item.controller.menu)) {
        menu.add(item);
      }
    });

    _items.clear();
    newMenu.forEach((item) {
      _items.add(menu.firstWhere((nav) => nav.controller.menu == item));
    });

    _initControl();
  }

  @override
  Widget build(BuildContext context) {
    return ControlBuilder(
      controller: widget.control.pageIndex,
      builder: (context, index) {
        final stack = IndexedStack(
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

class _InstantRoute extends PageRoute {
  final WidgetBuilder builder;

  _InstantRoute({@required this.builder}) : super();

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration();
}
