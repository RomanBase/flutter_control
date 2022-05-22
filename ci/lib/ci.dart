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

Future runModules(Future Function(Shell sh) func) async {
  for (var value in modules) {
    await func.call(moduleShell(value));
  }
}

Future runExamples(Future Function(Shell sh) func) async {
  for (var value in examples) {
    await func.call(exampleShell(value));
  }
}

Future runScript(String script) async {
  await shell.run(script);
  await runModules((sh) => sh.run(script));
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

Future pubGet() async {
  await runScript('flutter pub get');
}

Future dartfmt() async {
  await shell.run('flutter dartfmt .');
}
