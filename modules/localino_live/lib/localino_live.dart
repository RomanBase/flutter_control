library localino_live;

import 'dart:convert';
import 'dart:io';

import 'package:control_core/core.dart';
import 'package:http/http.dart' as http;
import 'package:localino/localino.dart';
import 'package:path_provider/path_provider.dart' as path;

part 'src/api.dart';

part 'src/local_repo.dart';

part 'src/remote_repo.dart';

class LocalinoLive {
  static LocalinoRemoteApi instance(LocalinoRemoteOptions options) =>
      _LocalinoLiveApi(options);

  static Initializer<LocalinoRemoteApi> get remote =>
      (args) => instance(Parse.getArg<LocalinoRemoteOptions>(args)!);

  static Map<Type, Initializer> get initializers => {
        LocalinoRemoteApi: (args) =>
            instance(Parse.getArg<LocalinoRemoteOptions>(args)!),
      };
}
