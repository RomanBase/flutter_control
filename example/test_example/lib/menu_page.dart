import 'package:flutter_control/core.dart';
import 'package:flutter_control_example/cross_page.dart';
import 'package:flutter_control_example/swap_page.dart';

import 'cards_page.dart';
import 'settings_page.dart';

class MenuPage extends StatelessWidget with LocalizationProvider {
  final controller = NavigatorStackControl(initialPageIndex: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ObjectKey(controller),
      body: NavigatorStack.menu(
        control: controller,
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
            iconBuilder: (selected) => Icons.crop,
            titleBuilder: (selected) => localize('cross'),
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
      bottomNavigationBar: ActionBuilder(
        control: controller.pageIndex,
        builder: (context, index) {
          return BottomNavigationBar(
            onTap: controller.setPageIndex,
            type: BottomNavigationBarType.fixed,
            currentIndex: index,
            items: [
              for (final item in controller.menuItems)
                BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  title: Text(item.title),
                )
            ],
          );
        },
      ),
    );
  }
}
