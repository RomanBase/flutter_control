import 'package:flutter_control/core.dart';

import 'cards_page.dart';
import 'settings_page.dart';
import 'tabs_page.dart';

class CustomNavigatorStackController extends NavigatorStackController with StateController {
  bool show5 = false;
  int initialIndex = 1;

  void toggle() => show5 ? switchTo4() : switchTo5();

  void switchTo4() {
    show5 = false;
    initialIndex = 1;
    notifyState();
  }

  void switchTo5() {
    show5 = true;
    initialIndex = 4;
    notifyState();
  }
}

class MenuPage extends ControlWidget {
  final controller = CustomNavigatorStackController();

  @override
  List<BaseControlModel> initControllers() => [controller];

  @override
  void onInitState(ControlState<ControlWidget> state) {
    super.onInitState(state);

    ControlProvider.set(value: controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigatorStack.menu(
        initialIndex: controller.initialIndex,
        controller: controller,
        items: controller.show5 ? items5 : items4,
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

  Map<MenuItem, WidgetBuilder> get items4 => {
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
        MenuItem(
          key: 'tabs',
          iconBuilder: (selected) => Icons.table_chart,
          titleBuilder: (selected) => 'tabs',
        ): (context) => TabsPage(),
      };

  Map<MenuItem, WidgetBuilder> get items5 => {
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
        MenuItem(
          key: 'tabs',
          iconBuilder: (selected) => Icons.table_chart,
          titleBuilder: (selected) => 'tabs',
        ): (context) => TabsPage(),
        MenuItem(
          key: 'empty',
          iconBuilder: (selected) => Icons.clear,
          titleBuilder: (selected) => 'empty',
        ): (context) => Center(
              child: Text('5th page'),
            ),
      };
}
