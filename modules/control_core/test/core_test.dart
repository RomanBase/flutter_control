import 'package:control_core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('init', () async {
    var initialized = Control.initControl();

    await Control.factory.onReady();

    Control.factory.printDebugStore();

    expect(initialized, isTrue);
  });
}
