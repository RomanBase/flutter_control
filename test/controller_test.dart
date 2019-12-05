import 'package:flutter_control/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Field Control', () {
    test('value modification', () {
      final controller = FieldControl<int>(1);

      controller.setValue(controller.value + 1);

      expect(controller.value, 2);
    });
  });
}
