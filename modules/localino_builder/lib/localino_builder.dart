import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:localino_builder/localino_remote_repo.dart';

const _defaultAssetPath = 'assets/localization/{locale}.json';

class LocalinoBuilder extends Builder {
  final api = LocalinoRemoteRepo();

  LocalinoBuilder(String space, String project, String access) {
    api.space = space;
    api.project = project;
    api.token = access;

    print('Localino Builder Initialized: $space - $project | $access}');
  }

  @override
  FutureOr<void> build(BuildStep? buildStep) async {
    final setup = await api.getSetup();
    final setupJson = jsonDecode(setup);
    final asset = setupJson['asset'] ?? _defaultAssetPath;
    final locales = (setupJson['locales'] as Map?)?.keys ?? [];

    _storeSetup(asset, setup);
    print('Available Locales: $locales');

    for (final locale in locales) {
      final translations = await api.getLocale(locale).catchError((err) {
        print(err);
        return '';
      });

      if (translations.isNotEmpty) {
        _storeLocale(asset, locale, translations);
        print('Locale stored: $locale');
      }
    }
  }

  void _storeSetup(String asset, String data) => _writeAsString(_fileJson(asset, 'setup'), data);

  void _storeLocale(String asset, String locale, String data) => _writeAsString(_fileJson(asset, locale), data);

  File _fileJson(String asset, String name) => File('./${asset.replaceFirst('{locale}', name)}');

  void _writeAsString(File file, String text) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    file.writeAsStringSync(text);
  }

  @override
  Map<String, List<String>> get buildExtensions => {};
}
