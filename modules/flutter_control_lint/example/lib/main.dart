import 'package:flutter/material.dart';

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
        // Cursor here -> "Wrap with ControlBuilder".
        body: Center(child: Text('hello')),
      ),
    );
  }
}
