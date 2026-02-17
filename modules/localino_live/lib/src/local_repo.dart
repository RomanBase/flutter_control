part of localino_live;

/// A helper class to handle file system operations for a specific locale cache.
class _LocaleStorage {
  /// The path to the cache file.
  final Uri path;

  const _LocaleStorage(this.path);

  /// Creates a [_LocaleStorage] instance for a given [space], [project], and [locale].
  static Future<_LocaleStorage> of(
      String space, String project, String locale) async {
    final dir = await getTemporaryDirectory();

    return _LocaleStorage(
        Uri.parse('${dir.path}/localino/${space}_${project}_${locale}'));
  }

  /// Writes [bytes] to the cache file.
  Future<File> write(Uint8List bytes) async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      await file.create(recursive: true);
    }

    return file.writeAsBytes(bytes);
  }

  /// Reads all bytes from the cache file. Returns `null` if the file doesn't exist.
  Future<Uint8List?> read() async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      return null;
    }

    return file.readAsBytes();
  }

  /// Deletes the cache file.
  Future<void> delete() async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      return;
    }

    await file.delete(recursive: true);
  }
}

/// Manages the local cache for translations on the device's file system.
class LocalinoLocalRepo {
  LocalinoLocalRepo._();

  /// Stores a map of [translations] for a given [locale] to a local file.
  Future<void> storeLocaleToCache(String space, String project, String locale,
      Map<String, dynamic> translations) async {
    final storage = await _LocaleStorage.of(space, project, locale);

    await storage
        .write(Uint8List.fromList(utf8.encode(jsonEncode(translations))));
  }

  /// Loads translations for a given [locale] from a local file.
  /// Returns an empty map if the cache file is not found.
  Future<Map<String, dynamic>> loadLocaleFromCache(
      String space, String project, String locale) async {
    final storage = await _LocaleStorage.of(space, project, locale);

    final result = await storage.read();

    if (result != null) {
      return jsonDecode(utf8.decode(result));
    }

    return {};
  }

  /// Deletes the cached translation file for a given [locale].
  Future<void> deleteLocaleCache(
      String space, String project, String locale) async {
    final storage = await _LocaleStorage.of(space, project, locale);

    await storage.delete();
  }
}
