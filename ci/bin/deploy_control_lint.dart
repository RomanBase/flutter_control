import 'package:ci/ci.dart' as ci;

void main(List<String> arguments) async {
  await ci.runAsync(
    'deploy control_lint',
    () => ci.deployDart('control_lint'),
  );
}
