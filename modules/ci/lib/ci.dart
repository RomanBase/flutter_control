import 'package:process_run/shell.dart';

var shell = Shell();
var modules = [
  'control_core',
  'control_config',
  'localino',
  '',
];

Future pubGet() async {
  await run((sh) => sh.run('flutter pub get'));
}

Future dartfmt() async {
  await moduleShell('../').run('flutter dartfmt .');
}

Future run(Future Function(Shell sh) func) async {
  for (var value in modules) {
    await func.call(moduleShell(value));
  }
}

Shell moduleShell(String module) => shell.cd('../$module');
