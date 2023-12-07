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
  LocalinoLive._();

  static LocalinoRemoteApi instance(LocalinoRemoteOptions options) =>
      _LocalinoLiveApi(options);

  static LocalinoRemoteRepo repo(String token, [http.Client? client]) =>
      LocalinoRemoteRepo._(token, client);

  static LocalinoLocalRepo cache() => LocalinoLocalRepo._();

  static InitFactory<LocalinoRemoteApi> get _remote =>
      (args) => instance(Parse.getArg<LocalinoRemoteOptions>(args)!);

  static Map<Type, InitFactory> get initializers => {
        LocalinoRemoteApi: _remote,
      };

  static LocalinoOptions options({
    String path = 'assets/localization/setup.json',
    LocalinoSetup? setup,
    bool remoteSync = false,
  }) =>
      LocalinoOptions(
        path: path,
        setup: setup,
        remote: _remote,
        remoteSync: remoteSync,
      );
}
