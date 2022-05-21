import 'package:flutter_control/control.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_widget.dart';

void main() {
  group('Control Holder', () {
    test('args', () {
      final holder = ControlArgHolder();

      holder.set({String: 'arg1', 'key': 'arg2'});
      holder.set({String: 'arg3'});
      holder.set(10);
      holder.set([1.0, true]);

      expect(holder.args.length, 5);
      expect(Parse.getArg<String>(holder.args), isNot('arg1'));
      expect(Parse.getArg(holder.args, key: String), 'arg3');
      expect(Parse.getArg<int>(holder.args), 10);
      expect(Parse.getArg<double>(holder.args), 1.0);
    });
  });

  group('Widget', () {
    test('args', () {
      final widget1 = TestWidget('empty');
      final widget2 = TestWidget({'key': 'value'});

      // ignore: invalid_use_of_protected_member
      widget1.init({'init': true});

      widget1.addArg(0);
      widget2.addArg({int: 0});

      expect(widget1.getArg<String>(), 'empty');
      expect(widget1.getArg(key: 'init'), isTrue);
      expect(widget1.getArg<int>(), 0);
      expect(widget1.getArg<double>(defaultValue: 1.0), 1.0);

      expect(widget2.getArg<String>(), 'value');
      expect(widget2.getArg<int>(), 0);
      expect(widget2.getArg<double>(defaultValue: 1.0), 1.0);
    });

    testWidgets('init', (tester) async {
      final widget = TestWidget('empty');

      // ignore: invalid_use_of_protected_member
      widget.init({'init': true});

      await tester.pumpWidget(widget);

      final controller = widget.getControl<TestController>()!;

      expect(widget.isInitialized, isTrue);
      expect(widget.isValid, isTrue);
      // ignore: invalid_use_of_protected_member
      expect(widget.holder.isCacheActive, isFalse);
      // ignore: invalid_use_of_protected_member
      expect(widget.holder.args.length, 3); // 'empty', 'init', ControlModel
      expect(widget.getArg<String>(), 'empty');
      expect(widget.getArg(key: 'init'), isTrue);

      expect(controller, isNotNull);

      // ignore: invalid_use_of_protected_member
      expect(widget.controls!.length, 1);
      expect(controller.isInitialized, isTrue);
      expect(controller.value, isTrue);
    });

    testWidgets('single init', (tester) async {
      final widget = TestSingleWidget(TestController());

      // ignore: invalid_use_of_protected_member
      widget.init({'init': true});

      await tester.pumpWidget(widget);

      final controller = widget.control!;

      expect(widget.isInitialized, isTrue);
      expect(widget.getArg(key: 'init'), isTrue);

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
      expect(widget.getArg(key: 'init'), isTrue);

      // ignore: invalid_use_of_protected_member
      expect(widget.controls!.length, 0);
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

      expect(widget, isNotNull);
      // ignore: invalid_use_of_protected_member
      expect(
          widget.holder.args.length, 4); // '10', 'init', 'args', ControlModel.
      expect(widget.getArg<int>(), 10);
      expect(widget.getArg(key: String), 'init');
      expect(widget.getArg(key: 'key'), 'args');
    });
  });
}

class TestWidget extends ControlWidget {
  TestWidget(dynamic args) : super(args: args);

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  List<ControlModel> initControls() {
    return [TestController()];
  }
}

class TestBaseWidget extends ControlWidget {
  TestBaseWidget(dynamic args) : super(args: args);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TestSingleWidget extends SingleControlWidget<TestController> {
  TestSingleWidget(TestController controller) : super(args: controller);

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
