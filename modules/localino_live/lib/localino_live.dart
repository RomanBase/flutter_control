library localino_live;

import 'dart:convert';
import 'dart:io';

import 'package:control_core/core.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:localino/localino.dart';
import 'package:path_provider/path_provider.dart' as path;

part 'src/local_repo.dart';

part 'src/localino_api.dart';

part 'src/remote_repo.dart';

class LocalinoLive {
  static LocalinoRemoteApi instance(LocalinoRemoteOptions options) => LocalinoLiveApi(options);

  static Map<Type, Initializer> get initializers => {
        LocalinoRemoteApi: (args) => instance(Parse.getArg<LocalinoRemoteOptions>(args)!),
      };
}
