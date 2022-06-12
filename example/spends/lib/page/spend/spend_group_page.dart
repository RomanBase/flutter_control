import 'package:flutter_control/control.dart';
import 'package:spends/control/spend/spend_group_control.dart';
import 'package:spends/control/spend/spend_item_model.dart';
import 'package:spends/theme.dart';
import 'package:spends/widget/tab_row.dart';

import 'spend_group_edit_dialog.dart';
import 'spend_item_dialog.dart';
import 'spend_list_item.dart';

class SpendGroupPage extends SingleControlWidget<SpendGroupControl>
    with ThemeProvider<SpendTheme>, RouteControl {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Hero(
            tag: 'toolbar',
            child: Container(
              width: device.width,
              padding: EdgeInsets.only(
                  top: device.topBorderSize + theme.padding,
                  bottom: theme.padding,
                  left: theme.padding,
                  right: theme.padding),
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
                    style: theme.font.bodyText2,
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
                padding: EdgeInsets.only(
                    top: theme.paddingQuad, bottom: theme.paddingExtended),
                itemCount: data.length,
                itemBuilder: (context, index) => SpendListItem(
                  model: data[index],
                  onPressed: (item) {
                    routeOf<SpendItemDialog>()
                        .openDialog(args: [item, control]);
                  },
                  onRemove: (item) => control.removeItem(item),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.red,
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
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: close,
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => routeOf<SpendGroupEditDialog>()
                    .openDialog(args: control.group),
              ),
              SizedBox(
                width: theme.padding,
              ),
              ControlBuilder(
                control: control.group,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        control.group.item.title,
                        style: theme.font.headline6,
                      ),
                      if (control.group.item.hasNote)
                        Text(
                          control.group.item.note,
                          style:
                              theme.font.bodyText2.copyWith(color: theme.dark),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
