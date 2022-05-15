import 'package:flutter_control/core.dart';

typedef NavCallback<T> = T Function(bool selected);

class NavItem {
  final Object? key;
  final NavCallback<dynamic>? iconBuilder;
  final NavCallback<String>? titleBuilder;
  final Object? data;
  final bool selected;
  final ValueGetter<bool>? onSelected;

  dynamic get icon => iconBuilder != null ? iconBuilder!(selected) : null;

  String? get title => titleBuilder != null ? titleBuilder!(selected) : null;

  const NavItem({
    required this.key,
    this.iconBuilder,
    this.titleBuilder,
    this.data,
    this.selected: false,
    this.onSelected,
  });

  factory NavItem.static({
    required dynamic key,
    dynamic icon,
    String? title,
    Object? data,
    ValueGetter<bool>? onSelected,
  }) =>
      NavItem(
        key: key,
        iconBuilder: icon == null ? null : (_) => icon,
        titleBuilder: title == null ? null : (_) => title,
        data: data,
        onSelected: onSelected,
      );

  NavItem copyWith({
    Object? key,
    Object? data,
    bool? selected,
  }) =>
      NavItem(
        key: key ?? this.key,
        iconBuilder: iconBuilder ?? this.iconBuilder,
        titleBuilder: titleBuilder ?? this.titleBuilder,
        data: data ?? this.data,
        selected: selected ?? this.selected,
      );

  @override
  bool operator ==(other) {
    return other is NavItem && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// Helper interface to notify [State]
abstract class StackNavigationHandler {
  /// Navigate back withing [NavigatorStack]
  /// Returns [true] if navigation is handled by Controller.
  bool navigateBack();

  /// Navigate to first Widget of [NavigatorStack]
  void navigateToRoot();
}

/// Controller for [NavigatorStack]
class NavigatorControl extends BaseControl {
  /// Data for menu item.
  /// Mostly used in combination with [NavigatorStackControl]
  NavItem? menu;

  /// Implementation of StackNavigator.
  StackNavigationHandler? _navigator;

  /// Check if navigator is set during subscribe (State init) phase.
  bool get isNavigatorAvailable => _navigator != null;

  /// Data for menu item.
  /// Returns if this controller is selected.
  /// Mostly used in combination with [NavigatorStackControl]
  bool get selected => menu!.selected;

  /// Data for menu item.
  /// Sets selection for this controller.
  /// Mostly used in combination with [NavigatorStackControl]
  set selected(value) {
    menu = menu!.copyWith(selected: value);
    if (onSelectionChanged != null) {
      onSelectionChanged!(value);
    }
  }

  /// Notifies about selection changes.
  ValueCallback<bool>? onSelectionChanged;

  /// Default constructor
  NavigatorControl({this.menu}) {
    menu ??= NavItem(
      key: UniqueKey(),
    );
  }

  @override
  void register(object) {
    super.register(object);

    if (object is StackNavigationHandler) {
      _navigator = object;
    }
  }

  operator ==(other) {
    return other is NavigatorControl && menu == other.menu;
  }

  @override
  int get hashCode => menu.hashCode;

  bool navigateBack() =>
      _navigator != null ? _navigator!.navigateBack() : false;

  void navigateToRoot() => _navigator?.navigateToRoot();

  /// Helper function for [WillPopScope].
  /// Returns negation of [navigateBack] as Future.
  Future<bool> popScope() async => !navigateBack();
}

/// Controller for:
/// [NavigatorStack.group] - Multiple [NavigatorStack]s in [Stack]. Only selected Controllers are visible - [Offstage].
/// Typically just one page is visible - usable with [BottomNavigationBar] to preserve navigation of separated pages.
/// [NavigatorStack.menu] - Simplified version of [NavigatorStack.group], can be used if access to [NavigatorControl]s is not required.
///
/// [NavigatorStack]
class NavigatorStackControl extends BaseControl with ObservableComponent {
  /// List of Controllers set in Widget construct phase.
  List<NavigatorControl>? _items;

  /// List of Controllers set in Widget construct phase.
  List<NavigatorControl> get items =>
      isValid ? List.of(_items!, growable: false) : [];

  /// List of MenuItems set in Widget construct phase.
  List<NavItem?> get menuItems =>
      isValid ? _items!.map((item) => item.menu).toList(growable: false) : [];

  /// Returns current controller - based on [currentPageIndex].
  NavigatorControl get currentControl => _items![currentPageIndex];

  NavItem? get currentMenu => currentControl.menu;

  bool get isValid => _items != null && _items!.length > 0;

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
  ObservableValue<int?> get pageIndex => ObservableValue.of(_pageIndex);

  bool reloadOnReselect;

  VoidCallback? onPagesInitialized;

  int? _initialIndex;

  NavigatorStackControl({int? initialPageIndex, this.reloadOnReselect: true}) {
    _initialIndex = initialPageIndex;
    _pageIndex.value = _initialIndex ?? 0;
  }

  void initControls(List<NavigatorControl> controls) => _items = controls;

  NavigatorControl? getControl({int? index, NavItem? item, dynamic key}) {
    if (!isValid) {
      return null;
    }

    if (index != null) {
      return _items![index];
    }

    key ??= item?.key;

    if (key != null) {
      try {
        return _items!.firstWhere((element) => element.menu?.key == key);
      } on StateError {
        return null;
      }
    }

    return null;
  }

  /// Sets page index and notifies [pageIndex]
  /// Given index is clamped between valid indexes [items.length]
  /// Notifies [State] to switch Pages.
  void setPageIndex(int index) {
    if (!isValid || index < 0) {
      return;
    }

    if (currentPageIndex == index) {
      if (_items![index].menu?.onSelected != null) {
        if (_items![index].menu!.onSelected!()) {
          return;
        }
      }

      if (reloadOnReselect) {
        currentControl.reload();
      }

      return;
    }

    currentControl.selected = false;

    index = index.clamp(0, _items!.length - 1);

    if (_items![index].menu?.onSelected != null) {
      if (_items![index].menu!.onSelected!()) {
        return;
      }
    }

    _pageIndex.setValue(index);
    currentControl.selected = true;
  }

  void setPageByItem(NavItem? item) => setPageIndex(menuItems.indexOf(item));

  void setPageByKey(dynamic key) =>
      setPageByItem(menuItems.firstWhere((item) => item!.key == key,
          orElse: () => NavItem(key: null)));

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
