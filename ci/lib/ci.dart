import 'package:process_run/shell.dart';

final _shell = Shell().cd('../');
final modules = [
  'control_core',
  'control_config',
  'localino',
  'localino_live',
  'localino_builder',
];

final examples = [
  'test_example',
];

Shell rootShell() => _shell;

Shell moduleShell(String name) => _shell.cd('modules/$name');

Shell exampleShell(String name) => _shell.cd('example/$name');

Future proceedModules(Future Function(Shell sh) func) async {
  for (var value in modules) {
    await func.call(moduleShell(value));
  }
}

Future proceedExamples(Future Function(Shell sh) func) async {
  for (var value in examples) {
    await func.call(exampleShell(value));
  }
}

Future runInRoot(String script) => _shell.run(script);

Future runInModule(String name, String script) => moduleShell(name).run(script);

Future runInModules(String script) async {
  await proceedModules((sh) => sh.run(script));
  await _shell.run(script);
}

Future runInExamples(String script) async {
  await _shell.run(script);
  await proceedExamples((sh) => sh.run(script));
}

Future runAll(String script) async {
  await proceedModules((sh) => sh.run(script));
  await _shell.run(script);
  await proceedExamples((sh) => sh.run(script));
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

Future clean() async {
  await runInModules('flutter clean');
}

Future pubGet() async {
  await runInModules('flutter pub get');
}

Future dartfmt() async {
  await _shell.run('dart format .');
}

Future deploy(String module) async {
  await runInModule(module, 'echo "y" | flutter pub publish');
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

void runSync(dynamic parent, void Function() action) {
  print('CI $parent --- START');
  action();
  print('CI $parent --- END');
}

Future runAsync(dynamic parent, Future<void> Function() action) async {
  final timestamp = DateTime.now();
  print('CI $parent --- START');
  await action();
  final duration = DateTime.now().difference(timestamp);
  final inSec = duration.inSeconds > 0;
  print('CI $parent --- END | ${inSec ? duration.inSeconds : duration.inMilliseconds}${inSec ? 's' : 'ms'}');
}
