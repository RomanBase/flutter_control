import 'package:process_run/shell.dart';

final shell = Shell().cd('../');
final modules = [
  'control_core',
  'control_config',
  'localino',
];

final examples = [
  'test_example',
];

Shell moduleShell(String name) => shell.cd('modules/$name');

Shell exampleShell(String name) => shell.cd('example/$name');

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

Future runInModules(String script) async {
  await proceedModules((sh) => sh.run(script));
  await shell.run(script);
}

Future runInExamples(String script) async {
  await shell.run(script);
  await proceedExamples((sh) => sh.run(script));
}

Future runAll(String script) async {
  await proceedModules((sh) => sh.run(script));
  await shell.run(script);
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
  await shell.run('flutter dartfmt .');
}
