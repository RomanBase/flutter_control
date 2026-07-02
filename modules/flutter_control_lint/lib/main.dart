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
    registry.registerAssist(WrapWithControlBuilder.new);
    registry.registerAssist(WrapWithControlBuilderGroup.new);
    registry.registerAssist(WrapWithFieldBuilder.new);
    registry.registerAssist(WrapWithListBuilder.new);
  }
}
