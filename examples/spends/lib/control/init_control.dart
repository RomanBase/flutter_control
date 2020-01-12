import 'package:flutter_control/core.dart';

class InitControl extends InitLoaderControl {
  @override
  Future<dynamic> load() async {
    printDebug('custom load');

    return 'offline';
  }
}
