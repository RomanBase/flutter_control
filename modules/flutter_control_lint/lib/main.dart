import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/wrap_assist.dart';

/// Plugin entrypoint. The analysis server loads the top-level `plugin` object.
final plugin = _FlutterControlLintPlugin();

class _FlutterControlLintPlugin extends Plugin {
  @override
  String get name => 'flutter_control_lint';

  @override
  void register(PluginRegistry registry) {
    // PR1 spike: a single "Wrap with ControlBuilder" assist.
    // PR2 adds ControlBuilderGroup / FieldBuilder / ListBuilder.
    registry.registerAssist(WrapWithControlBuilder.new);
  }
}
