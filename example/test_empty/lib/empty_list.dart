import 'package:flutter_control/core.dart';

class EmptyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('list'),
      ),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) => EmptyItem(),
      ),
    );
  }
}

class EmptyItem extends ControlWidget {
  String get index => (controls[0] as UnitControl).index;

  @override
  List<ControlModel> initControls() =>
      [getControl<UnitControl>() ?? UnitControl()];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(32.0),
      height: 320.0,
      color: Colors.lightBlueAccent,
      child: Center(
        child: Column(
          children: [
            Text(
              index,
            ),
            Text(
              '${holder.args.length}',
            ),
            ControlBuilder<String>(
              control: controls[0],
              valueConverter: (control) => control.index,
              builder: (context, value) => Text('$value'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

int _unitIndex = 0;

class UnitControl extends BaseControl {
  final index = UnitId.charId(_unitIndex++);
}
