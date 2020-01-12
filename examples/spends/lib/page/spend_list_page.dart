import 'package:flutter_control/core.dart';
import 'package:spends/control/spend_control.dart';

class SpendListPage extends SingleControlWidget<SpendControl> with ThemeProvider {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.orange,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: device.topBorderSize + theme.padding, bottom: theme.padding, left: theme.padding, right: theme.padding),
              color: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FieldBuilder<String>(
                    control: control.yearSpend,
                    builder: (context, value) => Text(value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListBuilder(
                control: control.list,
                builder: (context, data) => ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: data.length,
                  itemBuilder: (context, index) => SpendItemWidget(
                    key: ObjectKey(data[index]),
                    item: data[index],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          control.addItem(SpendItem(
            title: UnitId.charId(control.list.length),
            value: control.list.length,
            subscription: false,
          ));
        },
      ),
    );
  }
}

class SpendItemWidget extends StatelessWidget {
  final SpendItem item;

  const SpendItemWidget({Key key, this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 96.0,
      color: Colors.grey,
      child: Text(item.title),
    );
  }
}
