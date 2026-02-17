import 'package:ci/ci.dart' as ci;

void main(List<String> args) async {
  await ci.dartfmt();
  return;

  await _fix('--code=annotate_overrides');
  await _fix('--code=prefer_const_constructors');
  await _fix('--code=prefer_const_constructors_in_immutables');
  await _fix('--code=prefer_const_declarations');
  await _fix('--code=prefer_const_literals_to_create_immutables');
  await _fix('--code=unnecessary_const');
  await _fix('--code=unnecessary_import');
  await _fix('--code=unnecessary_new');
  await _fix('--code=unnecessary_non_null_assertion');
  await _fix('--code=unnecessary_null_comparison');
  await _fix('--code=unnecessary_overrides');
  await _fix('--code=unnecessary_this');
  await _fix('--code=unused_import');
  await _fix('--code=use_super_parameters');
}

Future<void> _fix(String arg) => ci.shell.run('dart fix --apply $arg');
