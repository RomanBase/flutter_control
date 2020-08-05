import 'package:flutter_control/core.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:spends/control/earnings/earnings_item_model.dart';
import 'package:spends/entity/earnings_item.dart';
import 'package:spends/theme.dart';

class EarningsListItem extends SingleControlWidget<EarningsItemModel>
    with ThemeProvider<SpendTheme> {
  final ValueCallback<EarningsItemModel> onPressed;
  final ValueCallback<EarningsItemModel> onRemove;

  EarningsItem get item => control.item;

  EarningsListItem({
    @required EarningsItemModel model,
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
                      style: font.bodyText1,
                    ),
                    if (item.note != null)
                      Text(
                        item.note,
                        style: font.bodyText2,
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
                    item.yearEarnings.toInt().toString(),
                    style: item.isSub ? font.bodyText2 : font.bodyText1,
                  ),
                  Text(
                    item.monthEarnings.toInt().toString(),
                    style: item.isSub ? font.bodyText1 : font.bodyText2,
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
