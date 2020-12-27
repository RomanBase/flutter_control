import 'dart:math';

import 'package:flutter_control/core.dart';

class SwapPage extends StatefulWidget {
  final greenControl = SwapControl(Colors.green);

  final redControl = SwapControl(Colors.red);

  @override
  _SwapPageState createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  bool swap = false;

  SwapItem green;

  SwapItem red;

  @override
  void initState() {
    super.initState();

    green = SwapItem(widget.greenControl, Colors.white);
    red = SwapItem(widget.redControl, Colors.black);
  }

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
          CaseWidget(
            activeCase: widget.greenControl.count % 2 == 0,
            builders: {
              true: (_) => Container(
                    height: 24.0,
                    color: Colors.red,
                  ),
              false: (_) => Container(
                    height: 24.0,
                    color: Colors.green,
                  ),
            },
            placeholder: (_) => Container(
              height: 24.0,
              color: Colors.orange,
            ),
            transition: CrossTransition(
                duration: Duration(seconds: 3),
                builder: CrossTransitions.fadeOutFadeIn()),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: 100,
                itemBuilder: (c, i) => CaseWidget(
                      activeCase: Random().nextInt(4),
                      builders: {
                        0: (_) => CaseContainer(index: 0),
                        1: (_) => CaseContainer(index: 1),
                        2: (_) => CaseContainer(index: 2),
                        i: (_) => CaseContainer(index: i),
                      },
                      placeholder: (_) => CaseContainer(
                        index: -1,
                        color: Colors.amber,
                      ),
                    )),
          ),
        ],
      ),
    );
  }
}

class CaseContainer extends StatelessWidget {
  final int index;
  final Color color;

  const CaseContainer({Key key, this.index, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96.0,
      color: color,
      child: Center(
        child: Text('$index'),
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
