import 'package:flutter_control/core.dart';
import 'package:flutter_control_example/cross_page.dart';
import 'package:flutter_control_example/swap_page.dart';

import 'cards_page.dart';
import 'settings_page.dart';

class MenuPage extends SingleControlWidget<NavigatorStackControl>
    with LocalizationProvider {
  @override
  NavigatorStackControl initControl() =>
      NavigatorStackControl(initialPageIndex: 1);

  @override
  void onInit(Map args) {
    super.onInit(args);

    register(control.pageIndex.subscribe((value) => control.notifyState()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigatorStack.menu(
        control: control,
        items: {
          MenuItem(
            key: 'cards',
            iconBuilder: (selected) => Icons.credit_card,
            titleBuilder: (selected) => localize('card_title'),
          ): (context) => CardsPage(),
          MenuItem(
            key: 'settings',
            iconBuilder: (selected) => Icons.settings_applications,
            titleBuilder: (selected) => localize('settings'),
          ): (context) => SettingsPage(),
          MenuItem(
            key: 'cross',
            iconBuilder: (selected) => selected ? Icons.filter : Icons.crop,
            titleBuilder: (selected) =>
                selected ? localize('cross_up') : localize('cross'),
          ): (context) => CrossPage(),
          MenuItem(
            key: 'swap',
            iconBuilder: (selected) => Icons.swap_horiz,
            titleBuilder: (selected) => localize('swap'),
          ): (context) => SwapPage(),
          MenuItem(
            key: 'about',
            iconBuilder: (selected) => Icons.file_upload,
            titleBuilder: (selected) => localize('about'),
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
      bottomNavigationBar: control.isMenuValid
          ? BottomNavigationBar(
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
                    title: Text(item.title),
                  )
              ],
            )
          : null,
    );
  }
}
