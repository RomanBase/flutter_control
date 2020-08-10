import 'package:flutter_control/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  //final key = Key('lock');

  group('Field Control', () {
    test('value modification', () {
      final control = FieldControl<int>(1);

      control.setValue(control.value + 1);

      expect(control.value, 2);
    });

    test('value sub', () {
      final controller = FieldControl<int>(1);

      final sub1 = controller.subscribe((value) => expect(value, 1));
      controller.subscribe((value) => expect(value, 2), current: false);

      sub1.cancel();
      controller.setValue(controller.value + 1);
    });

    test('value stream to control', () {
      final controller = FieldControl<int>(1);
      final controllerSub = FieldControl<int>();
      final controllerConvSub = FieldControl<String>();

      controller.streamTo(controllerSub);
      controller.streamTo(controllerConvSub, converter: (value) => value.toString());

      expect(controllerSub.value, 1);
      expect(controllerConvSub.value, '1');

      controllerSub.subscribe((value) => expect(value, 2), current: false);
      controllerConvSub.subscribe((value) => expect(value, '2'), current: false);

      controller.setValue(controller.value + 1);
    });

    test('value sub to control', () {
      final controller = FieldControl<int>(1);
      final controllerSub = FieldControl<int>();
      final controllerConvSub = FieldControl<String>();

      controllerSub.subscribeTo(controller.stream);
      controllerConvSub.subscribeTo(controller.stream, converter: (value) => value.toString());

      controllerSub.subscribe((value) => expect(value, 2), current: false);
      controllerConvSub.subscribe((value) => expect(value, '2'), current: false);

      expect(controllerSub.value, isNull);
      expect(controllerConvSub.value, isNull);

      controller.setValue(controller.value + 1);
    });

    test('value sink', () {
      final controller = FieldControl<int>(1);
      final sink = controller.sink;
      final sinkConv = controller.sinkConverter((value) => Parse.toInteger(value));

      controller.subscribe((value) => expect(value, 2), current: false);

      sink.add(2);
      sinkConv.add('2');

      sink.close();
      sinkConv.close();
    });

    test('cancel', () {
      final controller = FieldControl<int>(1);

      final sub1 = controller.subscribe((_) {});
      final sub2 = controller.subscribe((_) {});

      sub1.cancel();

      expect(sub1.isActive, isFalse);
      expect(sub2.isActive, isTrue);

      controller.dispose();

      expect(sub2.isActive, isFalse);

      sub2.cancel();
    });

    test('list sub to control', () {
      final controller = ListControl<int>([1, 2, 3, 4, 5, 6]);
      final controllerSub = ListControl<int>();
      final controllerConvSub = ListControl<String>();

      controller.filterTo(controllerSub, filter: (item) => item % 2 == 0);
      controller.filterTo(controllerConvSub, filter: (item) => item % 2 == 0, converter: (value) => Parse.toList(value, converter: (item) => item.toString()));

      expect(controllerSub[0], 2);
      expect(controllerConvSub[0], '2');
    });
  });

  group('Action Control', () {
    test('value modification', () {
      final controller = ActionControl.single<int>(1);

      controller.setValue(controller.value + 1);

      expect(controller.value, 2);
    });

    test('value with sub', () {
      final controller = ActionControl.single<int>(1);
      final sub = controller.sub;

      sub.once((value) => expect(value, 1));
      sub.once((value) => expect(value, 2), current: false);

      controller.setValue(sub.value + 1);
    });

    test('cancel', () {
      final controller = ActionControl.broadcast<int>(null);

      final sub1 = controller.once((_) {});
      final sub2 = controller.subscribe((_) {});
      final sub3 = controller.subscribe((_) {});

      controller.setValue(1);

      expect(sub1.isActive, isFalse);
      expect(sub2.isActive, isTrue);
      expect(sub3.isActive, isTrue);

      sub2.cancel();

      expect(sub2.isActive, isFalse);
      expect(sub3.isActive, isTrue);

      controller.cancel();

      expect(sub3.isActive, isFalse);
    });

    test('operator ==', () {
      final controllerA = ActionControl.single<int>(1);
      final controllerB = ActionControl.broadcast<int>(1);

      expect(controllerA == controllerB, true);
      // ignore: unrelated_type_equality_checks
      expect(controllerA == 1, true);
      expect(controllerA.equal(controllerB), false);
    });
  });

  group('Observable Group', () {
    test('value', () {
      final action = ActionControl.broadcast('action');
      final field = FieldControl('field');

      final group = ObservableGroup([action, field]);

      expect(group.length, 2);
      expect(group[0], 'action');
      expect(group[1], 'field');

      action.value = 'action_changed';
      expect(group[0], 'action_changed');

      group.subscribe((value) => expect(value.length, 2));
    });
  });
}
