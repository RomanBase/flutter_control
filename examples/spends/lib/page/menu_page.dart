import 'package:flutter_control/core.dart';
import 'package:spends/page/spend/spends_page.dart';
import 'package:spends/theme.dart';

import 'account/account_page.dart';
import 'earnings/earnings_item_dialog.dart';
import 'earnings/earnings_page.dart';
import 'spend/spend_item_dialog.dart';

class MenuPage extends SingleControlWidget<NavigatorStackControl> with RouteNavigator, ThemeProvider<SpendTheme> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigatorStack.menu(
        control: control,
        initialIndex: 1,
        items: {
          MenuItem(
            key: 'filter',
            iconBuilder: (_) => Icons.sort,
            onSelected: () {
              printDebug('filter selected');
              return true;
            },
          ): null,
          MenuItem(
            key: 'spends',
            iconBuilder: (_) => Icons.account_balance_wallet,
          ): (_) => SpendsPage(),
          MenuItem(
            key: 'earnings',
            iconBuilder: (_) => Icons.account_balance,
          ): (_) => EarningsPage(),
          MenuItem(
            key: 'account',
            iconBuilder: (_) => Icons.person,
            onSelected: () {
              routeOf<AccountPage>().openRoute();
              return true;
            },
          ): null,
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: () {
          switch (control.currentMenu.key) {
            case 'spends':
              routeOf<SpendItemDialog>().openDialog(type: DialogType.popup);
              break;
            case 'earnings':
              routeOf<EarningsItemDialog>().openDialog(type: DialogType.popup);
              break;
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        color: theme.gray,
        child: Container(
          height: theme.buttonHeight,
          child: ActionBuilder<int>(
            control: control.pageIndex,
            builder: (context, index) {
              return Row(
                children: <Widget>[
                  for (MenuItem item in control.menuItems)
                    Visibility(
                      visible: item != control.currentMenu,
                      child: IconButton(
                        icon: Icon(
                          item.icon,
                        ),
                        onPressed: () => control.setMenuItem(item),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
