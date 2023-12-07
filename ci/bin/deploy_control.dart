import 'package:ci/ci.dart' as ci;

void main(List<String> arguments) async {
  await ci.runAsync('deploy control', () => ci.runInRoot('echo "y" | flutter pub publish'));
}
