import 'package:flutter_control/core.dart';
import 'package:spends/control/spend/spend_group_control.dart';
import 'package:spends/control/spend/spend_item_model.dart';
import 'package:spends/main.dart';
import 'package:spends/widget/tab_row.dart';

import 'spend_item_dialog.dart';
import 'spend_list_page.dart';

class SpendGroupPage extends SingleControlWidget<SpendGroupControl> with ThemeProvider<SpendTheme>, RouteNavigator {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            width: device.width,
            padding: EdgeInsets.only(top: device.topBorderSize + theme.padding, bottom: theme.padding, left: theme.padding, right: theme.padding),
            color: theme.primaryColor,
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
          Expanded(
            child: ListBuilder<SpendItemModel>(
              control: control.list,
              builder: (context, data) => ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: theme.paddingQuad, bottom: theme.paddingExtended),
                itemCount: data.length,
                itemBuilder: (context, index) => SpendItemWidget(
                  model: data[index],
                  onPressed: (item) {
                    routeOf<SpendItemDialog>().openDialog(args: [item, control]);
                  },
                  onRemove: (item) => control.removeItem(item),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          //size: theme.iconSizeLarge,
        ),
        onPressed: () => routeOf<SpendItemDialog>().openDialog(args: control),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        color: theme.gray,
        child: Container(
          height: theme.buttonHeight,
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: close,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  control.group.item.title,
                  style: font.title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
