import 'package:flutter_control/control.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_widget.dart';

void main() {
  group('Widget', () {
    test('args', () {
      final widget1 = TestWidget('empty');
      final widget2 = TestWidget({'key': 'value'});

      // ignore: invalid_use_of_protected_member
      widget1.init({'init': true});

      widget1.args.set(0);
      widget2.args.set({int: 0});

      expect(widget1.args.get<String>(), 'empty');
      expect(widget1.args.get(key: 'init'), isTrue);
      expect(widget1.args.get<int>(), 0);
      expect(widget1.args.get<double>(defaultValue: 1.0), 1.0);

      expect(widget2.args.get<String>(), 'value');
      expect(widget2.args.get<int>(), 0);
      expect(widget2.args.get<double>(defaultValue: 1.0), 1.0);
    });

    testWidgets('single init', (tester) async {
      final widget = TestSingleWidget(TestController());

      // ignore: invalid_use_of_protected_member
      widget.init({'init': true});

      await tester.pumpWidget(widget);

      final controller = widget.control;

      expect(widget.isInitialized, isTrue);
      expect(widget.args.get(key: 'init'), isTrue);

      expect(controller, isNotNull);
      expect(controller.isInitialized, isTrue);
      expect(controller.value, isTrue);
    });

    testWidgets('arg control init', (tester) async {
      final widget = TestBaseWidget(TestController());

      // ignore: invalid_use_of_protected_member
      widget.init({'init': true});

      await tester.pumpWidget(widget);

      expect(widget.isInitialized, isTrue);
      expect(widget.args.get(key: 'init'), isTrue);

      // ignore: invalid_use_of_protected_member
      expect(widget.stateNotifiers.length, 0);
    });
  });

  group('Initializer', () {
    testWidgets('wrapper', (tester) async {
      final initializer = WidgetInitializer.of((context) => TestWidget(10));
      initializer.data = 'init';

      await tester.pumpWidget(
          Builder(builder: initializer.wrap(args: {'key': 'args'})));

      expect(initializer.isInitialized, isTrue);

      final widget = initializer.getWidget(MockBuildContext()) as TestWidget;

      await tester.pumpWidget(widget);

      expect(widget, isNotNull);
      // ignore: invalid_use_of_protected_member
      expect(widget.args.data.length,
          5); // '10', 'init', 'args', ControlModel (from TestWidget), CoreElement (from CoreWidget)
      expect(widget.args.get<int>(), 10);
      expect(widget.args.get(key: String), 'init');
      expect(widget.args.get(key: 'key'), 'args');
    });
  });
}

class TestWidget extends ControlWidget {
  TestWidget(dynamic args) : super(initArgs: ControlArgs.of(args).data);

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  List<ControlModel> initControls(CoreContext context) {
    return [TestController()];
  }
}

class TestBaseWidget extends ControlWidget {
  TestBaseWidget(dynamic args) : super(initArgs: ControlArgs.of(args).data);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TestSingleWidget extends SingleControlWidget<TestController> {
  TestSingleWidget(TestController controller)
      : super(initArgs: ControlArgs.of(controller).data);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TestController extends BaseControl {
  bool? value;

  @override
  void onInit(Map args) {
    super.onInit(args);

    value = args.getArg(key: 'init');
  }
}
