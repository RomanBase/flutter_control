import 'package:flutter_control/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final key = Key('lock');

  group('Field Control', () {
    test('value modification', () {
      final controller = FieldControl<int>(1);

      controller.setValue(controller.value + 1);

      expect(controller.value, 2);
    });
  });

  group('Action Control', () {
    test('value modification', () {
      final controller = ActionControl<int>.single(1);

      controller.setValue(controller.value + 1);

      expect(controller.value, 2);
    });

    test('value lock', () {
      final controller = ActionControl<int>.single(1);

      controller.lock(key);
      controller.setValue(controller.value + 1);

      expect(controller.value, 1);
    });

    test('value unlock', () {
      final controller = ActionControl<int>.single(1);

      controller.lock(key);
      controller.setValue(controller.value + 1);

      controller.unlock(key);
      controller.setValue(controller.value + 1);

      expect(controller.value, 2);
    });

    test('value with lock', () {
      final controller = ActionControl<int>.single(1);

      controller.lock(key);
      controller.setValue(controller.value + 1, key: key);

      expect(controller.value, 2);
    });
  });
}
