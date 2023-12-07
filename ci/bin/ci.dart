import 'package:ci/ci.dart' as ci;

void main(List<String> arguments) async {
  ci.runAsync('clean and format', () async {
    await ci.clean();
    await ci.pubGet();
    await ci.dartfmt();
  });
}
