import 'package:ci/ci.dart' as ci;

void main(List<String> arguments) async {
  await ci.runAsync('deploy localino', () => ci.deploy('localino'));
}
