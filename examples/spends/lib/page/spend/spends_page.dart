import 'package:flutter_control/core.dart';
import 'package:spends/control/spend/spend_control.dart';
import 'package:spends/control/spend/spend_item_model.dart';
import 'package:spends/theme.dart';
import 'package:spends/widget/tab_row.dart';

import 'spend_group_page.dart';
import 'spend_item_dialog.dart';
import 'spend_list_item.dart';

class SpendsPage extends SingleControlWidget<SpendControl> with ThemeProvider<SpendTheme>, RouteNavigator {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Hero(
            tag: 'toolbar',
            child: Container(
              width: device.width,
              padding: EdgeInsets.only(top: device.topBorderSize + theme.padding, bottom: theme.padding, left: theme.padding, right: theme.padding),
              color: theme.primaryColorDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  TabRow(
                    title: 'Total year spends',
                    control: control.yearSpend,
                  ),
                  TabRow(
                    title: 'Average month spends',
                    control: control.monthAvgSpend,
                    style: font.body2,
                  ),
                  SizedBox(
                    height: theme.paddingQuarter,
                  ),
                  TabRow(
                    title: 'Sub month spends',
                    control: control.monthSubSpend,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListBuilder<SpendItemModel>(
              control: control.list,
              builder: (context, data) => ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: theme.paddingQuad, bottom: theme.paddingExtended),
                itemCount: data.length,
                itemBuilder: (context, index) => SpendListItem(
                  model: data[index],
                  onPressed: (item) {
                    if (item.item.isGroup) {
                      routeOf<SpendGroupPage>().openRoute(args: item, root: true);
                    } else {
                      routeOf<SpendItemDialog>().openDialog(args: item);
                    }
                  },
                  onRemove: (item) => control.removeItem(item),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
