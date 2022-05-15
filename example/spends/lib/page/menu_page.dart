import 'package:flutter_control/core.dart';
import 'package:spends/page/spend/spends_page.dart';
import 'package:spends/theme.dart';

import 'account/account_page.dart';
import 'earnings/earnings_item_dialog.dart';
import 'earnings/earnings_page.dart';
import 'spend/spend_item_dialog.dart';

class MenuPage extends SingleControlWidget<NavigatorStackControl>
    with RouteControl, ThemeProvider<SpendTheme> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigatorStack.menu(
        control: control,
        initialIndex: 1,
        items: {
          NavItem(
            key: 'filter',
            iconBuilder: (_) => Icons.sort,
            onSelected: () {
              printDebug('filter selected');
              return true;
            },
          ): null,
          NavItem(
            key: 'spends',
            iconBuilder: (_) => Icons.account_balance_wallet,
          ): (_) => SpendsPage(),
          NavItem(
            key: 'earnings',
            iconBuilder: (_) => Icons.account_balance,
          ): (_) => EarningsPage(),
          NavItem(
            key: 'account',
            iconBuilder: (_) => Icons.person,
            onSelected: () {
              routeOf<AccountPage>().openRoute();
              return true;
            },
          ): null,
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: ActionBuilder<int>(
        control: control.pageIndex,
        builder: (context, value) => _actionButton(value == 2),
      ),
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
                  for (NavItem item in control.menuItems)
                    Visibility(
                      visible: item != control.currentMenu,
                      child: IconButton(
                        icon: Icon(
                          item.icon,
                        ),
                        onPressed: () => control.setPageByItem(item),
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

  Widget _actionButton(bool toAccent) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: toAccent ? 1.0 : 0.0),
      duration: theme.animDurationFast,
      curve: Curves.easeIn,
      builder: (context, value, child) {
        return FloatingActionButton(
          backgroundColor: Color.lerp(theme.red, theme.yellow, value),
          child: Icon(
            Icons.add,
            color: Color.lerp(theme.white, theme.dark, value),
          ),
          onPressed: () {
            switch (control.currentMenu.key) {
              case 'spends':
                routeOf<SpendItemDialog>().openDialog();
                break;
              case 'earnings':
                routeOf<EarningsItemDialog>().openDialog();
                break;
            }
          },
        );
      },
    );
  }
}
