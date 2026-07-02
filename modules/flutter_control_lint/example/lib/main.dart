import 'package:flutter/material.dart';
import 'package:flutter_control/control.dart';

/// Manual-verification fixtures for the flutter_control_lint assists.
///
/// Open this file in VS Code or IntelliJ/Android Studio (with the plugin
/// enabled via analysis_options.yaml, after restarting the analysis server).
/// Place the cursor on one of the widget expressions below and trigger the
/// lightbulb / Quick Fix menu (VS Code: Cmd+.) or Alt+Enter (IntelliJ).
///
/// Expected: a "Wrap with ControlBuilder" assist appears. Applying it wraps the
/// widget:
///
///   Text('hello')
///   ->
///   ControlBuilder(control: control, builder: (context, value) {
///     return Text('hello');
///   })
///
/// (`control` is a placeholder to replace with a real observable.)
void main() => runApp(const _ExampleApp());

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // Put the cursor on any widget below and open the lightbulb. All four
        // assists are offered on every widget (the assist does not verify the
        // `control:` type — the developer wires that after wrapping):
        //   - Wrap with ControlBuilder       -> control: control, (context, value)
        //   - Wrap with ControlBuilderGroup  -> controls: [control], (context, values)
        //   - Wrap with FieldBuilder         -> control: control, (context, value)
        //   - Wrap with ListBuilder          -> control: control, (context, list)
        body: Column(
          children: [Text('hello'), Icon(Icons.list), SizedBox(height: 8)],
        ),
      ),
    );
  }
}
