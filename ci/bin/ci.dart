import 'package:ci/ci.dart' as ci;

void main(List<String> arguments) async {
  print('CI --- start');
  await ci.pubGet();
  await ci.dartfmt();
  print('CI --- end');
}
