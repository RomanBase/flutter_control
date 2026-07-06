import 'package:control_lint/src/wrap_assist.dart';
import 'package:test/test.dart';

void main() {
  group('WrapAssistSpec output', () {
    test('ControlBuilder wraps into a control + builder callback', () {
      const spec = WrapAssistSpec(
        kindId: 'wrap_with_control_builder',
        widgetName: 'ControlBuilder',
        seedArgs: 'control: control,',
        builderParams: 'context, value',
      );

      expect(
        spec.opening(),
        'ControlBuilder(control: control, builder: (context, value) { return ',
      );
      expect(spec.closing, '; },)');

      // Wrapping `Text('x')`:
      //   opening + `Text('x')` + closing
      expect(
        '${spec.opening()}${"Text('x')"}${spec.closing}',
        "ControlBuilder(control: control, builder: (context, value) "
            "{ return Text('x'); },)",
      );
    });

    test('ControlBuilderGroup seeds a controls list and values param', () {
      const spec = WrapAssistSpec(
        kindId: 'wrap_with_control_builder_group',
        widgetName: 'ControlBuilderGroup',
        seedArgs: 'controls: [control],',
        builderParams: 'context, values',
      );

      expect(
        spec.opening(),
        'ControlBuilderGroup(controls: [control], '
        'builder: (context, values) { return ',
      );
    });

    test('FieldBuilder wraps into control + value', () {
      const spec = WrapAssistSpec(
        kindId: 'wrap_with_field_builder',
        widgetName: 'FieldBuilder',
        seedArgs: 'control: control,',
        builderParams: 'context, value',
      );

      expect(
        spec.opening(),
        'FieldBuilder(control: control, builder: (context, value) { return ',
      );
    });

    test('ListBuilder wraps into control + list', () {
      const spec = WrapAssistSpec(
        kindId: 'wrap_with_list_builder',
        widgetName: 'ListBuilder',
        seedArgs: 'control: control,',
        builderParams: 'context, list',
      );

      expect(
        spec.opening(),
        'ListBuilder(control: control, builder: (context, list) { return ',
      );
    });

    test('opening() honors a prefixed widget reference', () {
      const spec = WrapAssistSpec(
        kindId: 'wrap_with_control_builder',
        widgetName: 'ControlBuilder',
        seedArgs: 'control: control,',
        builderParams: 'context, value',
      );

      // When the import is prefixed (e.g. `as fc`), the resolved reference is
      // `fc.ControlBuilder`; the opening text must use it verbatim.
      expect(
        spec.opening('fc.ControlBuilder'),
        'fc.ControlBuilder(control: control, '
        'builder: (context, value) { return ',
      );
    });

    test('assistKind carries a human label and stable id', () {
      const spec = WrapAssistSpec(
        kindId: 'wrap_with_control_builder',
        widgetName: 'ControlBuilder',
        seedArgs: 'control: control,',
        builderParams: 'context, value',
      );

      expect(spec.assistKind.id, 'wrap_with_control_builder');
      expect(spec.assistKind.message, 'Wrap with ControlBuilder');
      expect(spec.assistKind.priority, wrapPriority);
    });
  });
}
