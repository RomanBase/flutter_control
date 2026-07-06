import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:localino_builder/localino_remote_repo.dart';
import 'package:localino_builder/src/key_generator.dart';
import 'package:localino_builder/src/key_parser.dart';
import 'package:localino_builder/src/unused_reporter.dart';

const _defaultAssetPath = 'assets/localization/{locale}.json';
const _keysOutputPath = './lib/generated/localino_keys.dart';

class LocalinoBuilder extends Builder {
  final api = LocalinoRemoteRepo();

  final bool generateKeys;
  final bool reportUnused;

  LocalinoBuilder(
    String space,
    String project,
    String access, {
    this.generateKeys = false,
    this.reportUnused = false,
  }) {
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

    final decodedByLocale = <String, Map>{};

    for (final locale in locales) {
      final translations = await api.getLocale(locale).catchError((err) {
        print(err);
        return '';
      });

      if (translations.isNotEmpty) {
        _storeLocale(asset, locale, translations);
        print('Locale stored: $locale');

        final decoded = jsonDecode(translations);
        if (decoded is Map) {
          decodedByLocale[locale.toString()] = decoded;
        }
      }
    }

    if (generateKeys) {
      _generateKeys(setupJson, decodedByLocale);
    }
  }

  void _generateKeys(Map setupJson, Map<String, Map> decodedByLocale) {
    if (decodedByLocale.isEmpty) {
      print('Localino: no locales decoded, skipping key generation');
      return;
    }

    final defaultLocale = resolveDefaultLocale(setupJson);
    final keys =
        parseLocalinoKeys(decodedByLocale, defaultLocale: defaultLocale);
    final source = generateLocalinoKeys(keys);

    _writeAsString(File(_keysOutputPath), source);
    print('Localino generated ${keys.length} keys -> $_keysOutputPath');

    if (reportUnused) {
      final unused = findUnusedKeys(keys, generatedPath: _keysOutputPath);
      if (unused.isEmpty) {
        print('Localino: no unused keys');
      } else {
        final names = unused.map((k) => k.jsonKey).join(', ');
        print('Localino: ${unused.length} unused keys: $names');
      }
    }
  }

  void _storeSetup(String asset, String data) =>
      _writeAsString(_fileJson(asset, 'setup'), data);

  void _storeLocale(String asset, String locale, String data) =>
      _writeAsString(_fileJson(asset, locale), data);

  File _fileJson(String asset, String name) =>
      File('./${asset.replaceFirst('{locale}', name)}');

  void _writeAsString(File file, String text) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    file.writeAsStringSync(text);
  }

  @override
  Map<String, List<String>> get buildExtensions => {};
}
