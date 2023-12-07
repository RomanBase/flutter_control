import 'package:ci/ci.dart' as ci;

void main(List<String> arguments) async {
  await ci.runAsync('deploy config', () => ci.deploy('control_config'));
}
