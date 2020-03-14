import 'package:d_navigation_stack/page/dialog_page.dart';
import 'package:d_navigation_stack/page/main_page.dart';
import 'package:flutter_control/core.dart';

class MenuPage extends SingleControlWidget<NavigatorStackControl> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigatorStack.menu(
        control: control,
        items: {
          MenuItem(
            titleBuilder: (_) => 'main',
            iconBuilder: (_) => Icons.dashboard,
          ): (_) => MainPage(),
          MenuItem(
            titleBuilder: (_) => 'dialog',
            iconBuilder: (_) => Icons.file_upload,
          ): (_) => DialogPage(),
          MenuItem(
            titleBuilder: (_) => 'menu',
            iconBuilder: (_) => Icons.info_outline,
            onSelected: () {
              showModalBottomSheet(
                context: getContext(root: false),
                builder: (_) => CustomDialog(),
                useRootNavigator: false,
              );
              return true;
            },
          ): (_) => null,
        },
      ),
      bottomNavigationBar: ActionBuilder<int>(
          control: control.pageIndex,
          builder: (context, value) {
            return BottomNavigationBar(
              currentIndex: value,
              onTap: control.setPageIndex,
              items: [
                for (final item in control.menuItems)
                  BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    title: Text(item.title),
                  ),
              ],
            );
          }),
    );
  }
}
