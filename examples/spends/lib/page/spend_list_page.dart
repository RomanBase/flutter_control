import 'package:flutter_control/core.dart';
import 'package:spends/control/spend_control.dart';

import '../control/spend_control.dart';
import 'spend_item_dialog.dart';

class SpendListPage extends SingleControlWidget<SpendControl> with ThemeProvider, RouteNavigator {
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
                  FieldBuilder<String>(
                    control: control.yearSpend,
                    builder: (context, value) => Text(value),
                  ),
                  FieldBuilder<String>(
                    control: control.monthAvgSpend,
                    builder: (context, value) => Text(
                      value,
                      style: font.body2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListBuilder(
                control: control.list,
                builder: (context, data) => ListView.builder(
                  padding: EdgeInsets.all(0.0),
                  itemCount: data.length,
                  itemBuilder: (context, index) => SpendItemWidget(
                    key: ObjectKey(data[index]),
                    item: data[index],
                    onPressed: (item) => routeOf<SpendItemDialog>().openDialog(type: DialogType.popup, args: item),
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

class SpendItemWidget extends StatelessWidget with ThemeProvider {
  final SpendItem item;
  final ValueCallback<SpendItem> onPressed;

  SpendItemWidget({
    Key key,
    @required this.item,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 1),
      color: Colors.grey,
      child: FlatButton(
        padding: EdgeInsets.all(theme.padding),
        onPressed: () => onPressed(item),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: font.headline,
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
                Text(item.yearSpend.toInt().toString()),
                Text(item.monthSpend.toInt().toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
