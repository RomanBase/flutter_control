import 'package:flutter_control/core.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:spends/control/spend/spend_control.dart';
import 'package:spends/control/spend/spend_item_model.dart';
import 'package:spends/entity/spend_item.dart';
import 'package:spends/theme.dart';
import 'package:spends/widget/tab_row.dart';

import 'spend_group_page.dart';
import 'spend_item_dialog.dart';

class SpendsPage extends SingleControlWidget<SpendControl> with ThemeProvider<SpendTheme>, RouteNavigator {
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

class SpendItemWidget extends SingleControlWidget<SpendItemModel> with ThemeProvider<SpendTheme> {
  final ValueCallback<SpendItemModel> onPressed;
  final ValueCallback<SpendItemModel> onRemove;

  SpendItem get item => control.item;

  SpendItemWidget({
    @required SpendItemModel model,
    @required this.onPressed,
    @required this.onRemove,
  }) : super(key: ObjectKey(model), args: model);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      child: Container(
        margin: EdgeInsets.only(top: 1),
        child: FlatButton(
          padding: EdgeInsets.symmetric(horizontal: theme.padding, vertical: theme.paddingQuarter),
          onPressed: () => onPressed(control),
          child: Row(
            children: <Widget>[
              LoadingBuilder(
                control: control.loading,
                progress: (_) => Padding(
                  padding: EdgeInsets.only(right: theme.padding),
                  child: CircularProgressIndicator(),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: font.body1,
                    ),
                    if (item.note != null)
                      Text(
                        item.note,
                        style: font.body2,
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: theme.padding,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    item.yearSpend.toInt().toString(),
                    style: item.isSub ? font.body2 : font.body1,
                  ),
                  Text(
                    item.monthSpend.toInt().toString(),
                    style: item.isSub ? font.body1 : font.body2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionPane: SlidableDrawerActionPane(),
      actions: <Widget>[
        IconSlideAction(
          caption: 'Delete',
          color: theme.red,
          icon: Icons.delete,
          onTap: () => onRemove(control),
        ),
      ],
    );
  }
}
