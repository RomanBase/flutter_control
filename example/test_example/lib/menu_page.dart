import 'package:flutter_control/control.dart';
import 'package:flutter_control_example/cross_page.dart';
import 'package:flutter_control_example/swap_page.dart';

import 'cards_page.dart';
import 'settings_page.dart';

class _NavObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route previousRoute) {
    super.didPush(route, previousRoute);

    printDebug('Observer push: $route');
  }

  @override
  void didPop(Route route, Route previousRoute) {
    super.didPop(route, previousRoute);

    printDebug('Observer pop: $route');
  }
}

class MenuPage extends SingleControlWidget<NavigatorStackControl>
    with LocalinoProvider {
  @override
  NavigatorStackControl initControl() =>
      NavigatorStackControl(initialPageIndex: 1);

  @override
  void onInit(Map args) {
    super.onInit(args);

    //register(control.pageIndex.subscribe((value) => control.notify()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigatorStack.menu(
        control: control,
        items: {
          NavItem(
            key: 'cards',
            iconBuilder: (selected) => Icons.credit_card,
            titleBuilder: (selected) => localize('card_title'),
            observers: [_NavObserver()],
          ): (context) => CardsPage(),
          NavItem(
            key: 'settings',
            iconBuilder: (selected) => Icons.settings_applications,
            titleBuilder: (selected) => localize('settings'),
            observers: [_NavObserver()],
          ): (context) => SettingsPage(),
          NavItem(
            key: 'cross',
            iconBuilder: (selected) => selected ? Icons.filter : Icons.crop,
            titleBuilder: (selected) =>
                selected ? localize('cross_up') : localize('cross'),
            observers: [_NavObserver()],
          ): (context) => CrossPage(),
          NavItem(
            key: 'swap',
            iconBuilder: (selected) => Icons.swap_horiz,
            titleBuilder: (selected) => localize('swap'),
            observers: [_NavObserver()],
          ): (context) => SwapPage(),
          NavItem(
            key: 'about',
            iconBuilder: (selected) => Icons.file_upload,
            titleBuilder: (selected) => localize('about'),
            observers: [_NavObserver()],
            onSelected: () {
              showAboutDialog(
                context: context,
                applicationName: 'Flutter Control',
                applicationVersion: '1.0',
              );
              return true;
            },
          ): (context) => Container(),
        },
      ),
      bottomNavigationBar: ControlBuilder<int>(
          control: control.pageIndex,
          builder: (context, snapshot) {
            return BottomNavigationBar(
              onTap: control.setPageIndex,
              type: BottomNavigationBarType.fixed,
              currentIndex: control.currentPageIndex,
              items: [
                for (final item in control.menuItems)
                  BottomNavigationBarItem(
                    icon: Icon(
                      item.icon,
                      color: item.selected ? Colors.red : Colors.black,
                    ),
                    label: item.title,
                  )
              ],
            );
          }),
    );
  }
}
