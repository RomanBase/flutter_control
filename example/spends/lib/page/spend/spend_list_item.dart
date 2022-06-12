import 'package:flutter_control/control.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:spends/control/spend/spend_item_model.dart';
import 'package:spends/entity/spend_item.dart';
import 'package:spends/theme.dart';

class SpendListItem extends SingleControlWidget<SpendItemModel>
    with ThemeProvider<SpendTheme> {
  final ValueCallback<SpendItemModel> onPressed;
  final ValueCallback<SpendItemModel> onRemove;

  SpendItem get item => control.item;

  SpendListItem({
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
          padding: EdgeInsets.symmetric(
              horizontal: theme.padding, vertical: theme.paddingQuarter),
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
                      style: theme.font.bodyText1,
                    ),
                    if (item.note != null)
                      Text(
                        item.note,
                        style: theme.font.bodyText2,
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
                    style: item.isSub
                        ? theme.font.bodyText2
                        : theme.font.bodyText1,
                  ),
                  Text(
                    item.monthSpend.toInt().toString(),
                    style: item.isSub
                        ? theme.font.bodyText1
                        : theme.font.bodyText2,
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
