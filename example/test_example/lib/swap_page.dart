import 'package:flutter_control/core.dart';

class SwapPage extends StatefulWidget {
  @override
  _SwapPageState createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  bool swap = false;

  final green = SwapItem(SwapControl(Colors.green), Colors.white);

  final red = SwapItem(SwapControl(Colors.red), Colors.black);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: swap ? red : green,
              ),
              SizedBox(
                width: 16.0,
              ),
              Expanded(
                child: swap ? green : red,
              ),
            ],
          ),
          SizedBox(
            height: 32.0,
          ),
          RaisedButton(
            onPressed: () {
              setState(() {
                swap = !swap;
              });
            },
            child: Text('swap'),
          ),
        ],
      ),
    );
  }
}

class SwapItem extends ControlWidget {
  final SwapControl control;
  final Color color;

  SwapItem(this.control, this.color);

  @override
  void onUpdate(CoreWidget oldWidget) {
    super.onUpdate(oldWidget);

    if (control.color == Colors.green) {
      control.count++;
    } else {
      control.count--;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96.0,
      color: control.color,
      child: Center(
        child: Text(
          control.count.toString(),
          style: TextStyle(color: color),
        ),
      ),
    );
  }
}

class SwapControl extends ControlModel {
  Color color;
  int count = 0;

  SwapControl(this.color);

  @override
  void dispose() {
    super.dispose();

    printDebug('DISPOSE SWAP');
  }
}
