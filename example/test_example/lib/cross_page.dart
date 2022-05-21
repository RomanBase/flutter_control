import 'package:flutter_control/control.dart';

class CrossControl extends ControlModel with ReferenceCounter {
  final cross = ActionControl.single<String>('red');

  @override
  void dispose() {
    super.dispose();
    cross.dispose();

    printDebug('DISPOSE CROSS - no reference');
  }
}

class _UIControl extends ControlModel {
  CrossControl _cross;

  @override
  void init(Map args) {
    super.init(args);

    _cross = args.getArg<CrossControl>();

    printDebug(_cross);

    printDebug('INIT UI -------------------------------- UI');
    printDebug(args);
    printDebug('-------------------------------------------');
  }
}

class CrossPage extends SingleControlWidget<CrossControl> {
  @override
  List<ControlModel> initControls() => [
        initControl(),
        _UIControl(),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: CaseWidget.builder(
            control: control.cross,
            builders: {
              'blue': (_) => CrossControlPage('red', Colors.blue, control),
              'red': (_) => CrossControlPage('orange', Colors.red, control),
              'orange': (_) =>
                  CrossControlPage('placeholder', Colors.orange, control),
            },
            placeholder: (_) => CrossControlPage('blue', Colors.black, control),
            transition: CrossTransition.slide(
              duration: Duration(seconds: 3),
              end: Offset(0.0, 1.5),
            ),
            reverseOrder: () => true,
            reverseAnimation: () => control.cross.value == 'blue',
          ),
        ),
        RaisedButton(
          onPressed: notifyState,
          child: Text('notify state'),
        ),
        RaisedButton(
          onPressed: () => ControlScope.root.setOnboardingState(),
          child: Text('reload app'),
        ),
      ],
    );
  }
}

class CrossControlPage extends SingleControlWidget<CrossControl> {
  final String next;
  final Color color;

  CrossControlPage(this.next, this.color, dynamic args) : super(args: args);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RaisedButton(
            onPressed: () {
              control.cross.value = next;
            },
            color: Theme.of(context).primaryColor,
            child: Text(
              'cross to $next',
              textAlign: TextAlign.center,
            ),
          ),
          Text(UnitId.nextId()),
        ],
      ),
    );
  }
}
