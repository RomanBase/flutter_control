part of localino_live;

class _LocaleStorage {
  final Uri path;

  const _LocaleStorage(this.path);

  static Future<_LocaleStorage> of(
      String space, String project, String locale) async {
    final dir = await getTemporaryDirectory();

    return _LocaleStorage(
        Uri.parse('${dir.path}/localino/${space}_${project}_${locale}'));
  }

  Future<File> write(Uint8List bytes) async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      await file.create(recursive: true);
    }

    return file.writeAsBytes(bytes);
  }

  Future<Uint8List?> read() async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      return null;
    }

    return file.readAsBytes();
  }

  Future<void> delete() async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      return;
    }

    await file.delete(recursive: true);
  }
}

class LocalinoLocalRepo {
  LocalinoLocalRepo._();

  Future<void> storeLocaleToCache(String space, String project, String locale,
      Map<String, dynamic> translations) async {
    final storage = await _LocaleStorage.of(space, project, locale);

    await storage
        .write(Uint8List.fromList(utf8.encode(jsonEncode(translations))));
  }

  Future<Map<String, dynamic>> loadLocaleFromCache(
      String space, String project, String locale) async {
    final storage = await _LocaleStorage.of(space, project, locale);

    final result = await storage.read();

    if (result != null) {
      return jsonDecode(utf8.decode(result));
    }

    return {};
  }

  Future<void> deleteLocaleCache(
      String space, String project, String locale) async {
    final storage = await _LocaleStorage.of(space, project, locale);

    await storage.delete();
  }
}
