import 'package:flutter_control/control.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_widget.dart';

void main() {
  test('release', () {
    Control.factory.debug = false;

    expect(kDebugMode && Control.debug, isFalse);
    printDebug('this will not print');
  });

  test('debug', () {
    Control.factory.debug = true;

    expect(kDebugMode && Control.debug, isTrue);
    printDebug('debug print');
  });

  test('object', () {
    Control.factory.debug = true;

    expect(kDebugMode && Control.debug, isTrue);
    printDebug(Control.factory);
  });

  test('typedefs', () {
    InitFactory<TestInitWidget> initializer =
        (args) => TestInitWidget(args: args);
    ValueCallback<String> valueCallback = (value) => expect(value, 'value');
    ValueConverter<String> valueConverter = (value) => value.toString();
    EntryConverter<String> entryConverter = (key, value) => '${key}_$value';
    ControlWidgetBuilder<String> controlWidgetBuilder =
        (context, value) => TestInitWidget(args: value);
    Predicate<String> predicate = (value) => value.isNotEmpty;

    final initObject = initializer('args');
    final initWidget =
        controlWidgetBuilder(MockBuildContext(), 'args') as TestInitWidget;

    valueCallback('value');

    expect(initObject, isNotNull);
    expect(initObject.args, 'args');

    expect(valueConverter(1), '1');
    expect(entryConverter(0, 'o'), '0_o');

    expect(initWidget, isNotNull);
    expect(initWidget.args, 'args');

    expect(predicate('val'), isTrue);
  });
}

class TestInitWidget extends StatelessWidget {
  final dynamic args;

  const TestInitWidget({Key? key, this.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
