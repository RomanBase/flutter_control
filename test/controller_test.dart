import 'package:flutter_control/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Controller test', () {
    final controller = FieldControl<int>(1);

    expect(controller.value, 1);
  });
}
