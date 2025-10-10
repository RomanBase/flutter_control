import 'package:process_run/shell.dart';

void main(List args) {
  Shell().run('dart run build_runner build');
}
