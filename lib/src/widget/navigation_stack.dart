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
    @required this.key,
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
  int get hashCode => key.hashCode;
}

/// Helper interface to notify [State]
abstract class _StackNavigator {
  /// Navigate back withing [NavigatorStack]
  /// Returns [true] if navigation is handled by Controller.
  bool navigateBack();

  /// Navigate to first Widget of [NavigatorStack]
  void navigateToRoot();
}

/// Controller for [NavigatorStack]
///
/// [NavigatorStackControl]
/// [WillPopScope]
/// [RouteHandler]  [RouteControlProvider]
class NavigatorControl extends BaseControl {
  /// Data for menu item.
  /// Mostly used in combination with [NavigatorStackControl]
  MenuItem menu;

  /// Implementation of StackNavigator.
  _StackNavigator _navigator;

  /// Check if navigator is set during subscribe (State init) phase.
  bool get isNavigatorAvailable => _navigator != null;

  /// Data for menu item.
  /// Returns if this controller is selected.
  /// Mostly used in combination with [NavigatorStackControl]
  bool get selected => menu.selected;

  /// Data for menu item.
  /// Sets selection for this controller.
  /// Mostly used in combination with [NavigatorStackControl]
  set selected(value) {
    menu = menu.copyWith(selected: value);
    if (onSelectionChanged != null) {
      onSelectionChanged(value);
    }
  }

  /// Notifies about selection changes.
  ValueCallback<bool> onSelectionChanged;

  /// Default constructor
  NavigatorControl({this.menu}) {
    menu ??= MenuItem(
      key: UniqueKey(),
    );
  }

  @override
  void register(object) {
    super.register(object);

    if (object is _StackNavigator) {
      _navigator = object;
    }
  }

  operator ==(other) {
    return other is NavigatorControl && menu == other.menu;
  }

  @override
  int get hashCode => menu.hashCode;

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
/// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorControl]s is not required.
///
/// [NavigatorStackControl] is used to navigate between multiple [NavigatorStack]s.
///
/// [RouteHandler] [RouteControlProvider]
class NavigatorStack extends StatefulWidget {
  final NavigatorControl control;
  final WidgetInitializer initializer;
  final bool overrideNavigation;

  /// Default constructor
  const NavigatorStack._({
    Key key,
    @required this.control,
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
    NavigatorControl control,
    @required WidgetBuilder builder,
    bool overrideNavigation: false,
  }) {
    control ??= NavigatorControl();

    return NavigatorStack._(
      key: ObjectKey(control.menu.key),
      control: control,
      initializer: WidgetInitializer.of(builder),
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
  static Widget group({
    NavigatorStackControl control,
    int initialIndex,
    @required List<NavigatorStack> items,
    StackGroupBuilder builder,
    bool overrideNavigation: true,
  }) {
    return NavigatorStackGroup(
      control: control ?? NavigatorStackControl(),
      initialIndex: initialIndex,
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
    NavigatorStackControl control,
    int initialIndex,
    @required Map<MenuItem, WidgetBuilder> items,
    StackGroupBuilder builder,
    bool overrideNavigation: true,
  }) {
    final stack = List<NavigatorStack>();

    items.forEach((key, value) => stack.add(NavigatorStack.single(
          control: NavigatorControl(menu: key),
          builder: value ?? (_) => Container(),
        )));

    return NavigatorStack.group(
      control: control,
      initialIndex: initialIndex,
      items: stack,
      builder: builder,
      overrideNavigation: overrideNavigation,
    );
  }

  @override
  _NavigatorStackState createState() => _NavigatorStackState();
}

class _NavigatorStackState extends State<NavigatorStack>
    implements _StackNavigator {
  GlobalKey<NavigatorState> _navigatorKey;

  NavigatorState get navigator => _navigatorKey?.currentState;

  HeroController _heroController;

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
      observers: [_heroController],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
            builder: (context) =>
                widget.initializer.getWidget(context) ?? Container());
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
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return true;
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
/// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorControl]s is not required.
///
/// [NavigatorStack]
class NavigatorStackControl extends BaseControl with StateControl {
  /// List of Controllers set in Widget construct phase.
  List<NavigatorControl> _items;

  /// List of Controllers set in Widget construct phase.
  List<NavigatorControl> get items => _items;

  /// List of MenuItems set in Widget construct phase.
  List<MenuItem> get menuItems => _items == null
      ? []
      : _items.map((item) => item.menu).toList(growable: false);

  /// Returns current controller - based on [currentPageIndex].
  NavigatorControl get currentControl => _items[currentPageIndex];

  MenuItem get currentMenu => currentControl.menu;

  bool get isMenuValid => _items != null && items.length > 0;

  /// Notifies about page changes.
  /// Can be used with [ActionBuilder] to rebuild menu or highlight active widget.
  ///
  /// Use [setPageIndex] to change Page.
  final _pageIndex = ActionControl.broadcast<int>(0);

  /// Returns current page index.
  /// Use [setPageIndex] to change active controller.
  /// Use [pageIndex] to be notified about changes.
  int get currentPageIndex => _pageIndex.value;

  /// Subscription to listen about page index changes.
  ActionControlObservable<int> get pageIndex => _pageIndex.sub;

  bool reloadOnReselect;

  VoidCallback onPagesInitialized;

  int _initialIndex;

  NavigatorStackControl({int initialPageIndex, this.reloadOnReselect: true}) {
    _initialIndex = initialPageIndex;
    _pageIndex.value = _initialIndex ?? 0;
  }

  /// Sets page index and notifies [pageIndex]
  /// Given index is clamped between valid indexes [items.length]
  /// Notifies [State] to switch Pages.
  void setPageIndex(int index) {
    if (index < 0) {
      return;
    }

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

    index = index.clamp(0, _items.length - 1);

    if (items[index].menu?.onSelected != null) {
      if (items[index].menu.onSelected()) {
        return;
      }
    }

    _pageIndex.setValue(index);
    currentControl.selected = true;
  }

  void setPageByItem(MenuItem item) => setPageIndex(menuItems.indexOf(item));

  void setPageByKey(dynamic key) =>
      setPageByItem(menuItems.firstWhere((item) => item.key == key,
          orElse: () => MenuItem(key: null)));

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

    _items = null;
    _pageIndex.dispose();
  }
}

typedef StackGroupBuilder = Widget Function(
    BuildContext context, int index, List<NavigatorStack> items);

class StackGroupBuilders {
  static StackGroupBuilder get stack => (context, index, items) => IndexedStack(
        key: ObjectKey('page_stack'),
        index: index,
        children: items,
      );

  static StackGroupBuilder get single =>
      (context, index, items) => items[index];
}

/// [NavigatorStack]
/// [NavigatorControl]
/// [NavigatorStackControl]
class NavigatorStackGroup extends StatefulWidget {
  final NavigatorStackControl control;
  final List<NavigatorStack> items;
  final int initialIndex;
  final StackGroupBuilder builder;
  final bool overrideNavigation;

  NavigatorStackGroup({
    @required this.control,
    @required this.items,
    this.initialIndex,
    this.builder,
    this.overrideNavigation: true,
  }) : super(key: ObjectKey(control)) {
    assert(items.length > 0);
  }

  @override
  _NavigatorStackGroupState createState() => _NavigatorStackGroupState();
}

class _NavigatorStackGroupState extends State<NavigatorStackGroup>
    with SingleTickerProviderStateMixin {
  NavigatorStackControl get control => widget.control;

  List<NavigatorStack> _items;

  @override
  void initState() {
    super.initState();

    if (_items == null) {
      _items = widget.items;
    }

    control.register(this);

    _updateIndex();
    _initControl();
  }

  void _initControl() {
    control._items = _items.map((page) => page.control).toList(growable: false);
    control.setPageIndex(control.currentPageIndex);
    control.currentControl.selected = true;

    if (control.onPagesInitialized != null) {
      control.onPagesInitialized();
    }
  }

  void _updateIndex() {
    if (control._initialIndex == null && widget.initialIndex != null) {
      control._initialIndex = widget.initialIndex;
      control._pageIndex
          .setValue(control._initialIndex, notifyListeners: false);
    }
  }

  @override
  void didUpdateWidget(NavigatorStackGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateIndex();

    if (control != oldWidget.control) {
      _items = widget.items;
      _initControl();
      return;
    }

    final oldMenu = control.menuItems;
    final newMenu =
        widget.items.map((page) => page.control.menu).toList(growable: false);

    final oldMenuHasKeys =
        oldMenu.firstWhere((item) => item.key == null, orElse: () => null) ==
            null;
    final newMenuHasKeys =
        newMenu.firstWhere((item) => item.key == null, orElse: () => null) ==
            null;

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
    return ActionBuilder(
      control: widget.control.pageIndex,
      builder: (context, index) {
        final stack = (widget.builder ?? StackGroupBuilders.stack)(
            context, index, _items);

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
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      child;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration();
}
