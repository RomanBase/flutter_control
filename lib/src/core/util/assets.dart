class AssetPath {
  final String rootDir;

  const AssetPath({this.rootDir: 'assets'});

  /// Refers to assets/path
  String root(String path) =>
      path.startsWith('/') ? "$rootDir$path" : "$rootDir/$path";

  /// Refers to assets/images/name.ext
  /// Default [ext] is 'png'.
  String image(String name, [String ext = 'png']) => root("images/$name.$ext");

  /// Refers to assets/icons/name.ext
  /// Default [ext] is 'png'.
  String icon(String name, [String ext = 'png']) => root("icons/$name.$ext");

  /// Refers to assets/icons/name.svg
  String svg(String name) => root("icons/$name.svg");

  /// Refers to assets/data/name.ext
  String data(String name, String ext) => root("data/$name.$ext");

  /// Refers to assets/raw/name.ext
  String raw(String name, String ext) => root("raw/$name.$ext");

  /// Refers to assets/localization/name.ext
  /// Default [ext] is 'json'.
  String localization(String name, [String ext = 'json']) =>
      root("localization/$name.$ext");
}
