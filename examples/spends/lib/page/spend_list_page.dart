import 'package:flutter_control/core.dart';
import 'package:spends/control/spend_control.dart';
import 'package:spends/entity/spend_item.dart';

import '../control/spend_control.dart';
import 'spend_item_dialog.dart';

class SpendListPage extends SingleControlWidget<SpendControl> with ThemeProvider, RouteNavigator {
  Widget buildHeaderRow({@required String title, @required FieldControl<String> control, TextStyle style}) {
    style ??= font.body1;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: style,
          ),
        ),
        FieldBuilder<String>(
          control: control,
          builder: (context, value) => Text(
            value,
            style: style,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              width: device.width,
              padding: EdgeInsets.only(top: device.topBorderSize + theme.padding, bottom: theme.padding, left: theme.padding, right: theme.padding),
              color: theme.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  buildHeaderRow(
                    title: 'Total year spends',
                    control: control.yearSpend,
                  ),
                  buildHeaderRow(
                    title: 'Average month spends',
                    control: control.monthAvgSpend,
                    style: font.body2,
                  ),
                  SizedBox(
                    height: theme.paddingMid,
                  ),
                  buildHeaderRow(
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
                  padding: EdgeInsets.all(0.0),
                  itemCount: data.length,
                  itemBuilder: (context, index) => SpendItemWidget(
                    model: data[index],
                    onPressed: (item) => routeOf<SpendItemDialog>().openDialog(args: item),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => routeOf<SpendItemDialog>().openDialog(type: DialogType.popup),
      ),
    );
  }
}

class SpendItemWidget extends SingleControlWidget<SpendItemModel> with ThemeProvider {
  final ValueCallback<SpendItemModel> onPressed;

  SpendItem get item => control.item;

  SpendItemWidget({
    @required SpendItemModel model,
    @required this.onPressed,
  }) : super(key: ObjectKey(model), args: model);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 1),
      child: FlatButton(
        padding: EdgeInsets.symmetric(horizontal: theme.padding, vertical: theme.paddingMid),
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
                  style: font.body1,
                ),
                Text(
                  item.monthSpend.toInt().toString(),
                  style: font.body2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
