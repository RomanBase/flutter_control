import 'package:flutter_control/core.dart';

import 'cards_page.dart';
import 'settings_page.dart';

class MenuPage extends StatelessWidget with LocalizationProvider {
  final controller = NavigatorStackController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigatorStack.menu(
        controller: controller,
        pages: {
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
      bottomNavigationBar: ControlBuilder(
        controller: controller.pageIndex,
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
