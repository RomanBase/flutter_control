import 'package:ci/ci.dart' as ci;

void main(List<String> arguments) async {
  await ci.runAsync('deploy core', () => ci.deploy('control_core'));
}
