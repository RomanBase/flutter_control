part of localino_live;

class _LocalRepo {
  Future<Uri> localePath(String space, String locale) async {
    final dir = await path.getTemporaryDirectory();

    return Uri.parse('${dir.path}/localino/${space}_${locale}');
  }

  Future<File> write(Uri path, Uint8List bytes) async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      await file.create(recursive: true);
    }

    return file.writeAsBytes(bytes);
  }

  Future<Uint8List?> read(Uri path) async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      return null;
    }

    return file.readAsBytes();
  }

  Future<void> delete(Uri path) async {
    final file = File.fromUri(path);
    final exists = await file.exists();

    if (!exists) {
      return;
    }

    await file.delete(recursive: true);
  }

  Future<void> storeLocaleToCache(String space, String locale, Map<String, dynamic> translations) async {
    if (kIsWeb) {
      printDebug('Localino Live cache is not supported on web');
      return;
    }

    final path = await localePath(space, locale);

    await write(path, Uint8List.fromList(utf8.encode(jsonEncode(translations))));
  }

  Future<Map<String, dynamic>> loadLocaleFromCache(String space, String locale) async {
    if (kIsWeb) {
      printDebug('Localino Live cache is not supported on web');
      return {};
    }

    final path = await localePath(space, locale);

    final result = await read(path);

    if (result != null) {
      return jsonDecode(utf8.decode(result));
    }

    return {};
  }

  Future<void> deleteLocaleCache(String space, String locale) async {
    if (kIsWeb) {
      printDebug('Localino Live cache is not supported on web');
      return;
    }

    final path = await localePath(space, locale);

    await delete(path);
  }
}
