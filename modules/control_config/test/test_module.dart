import 'package:control_config/config.dart';
import 'package:control_core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modules', () {
    ConfigModule.standalone();

    Control.factory.debug = true;
    Control.factory.printDebugStore();

    expect(Control.factory.containsKey(ControlPrefs), isTrue);
    expect(Control.get<ControlPrefs>(), isNotNull);
  });
}
