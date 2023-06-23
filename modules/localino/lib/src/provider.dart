part of localino;

/// Mixin class to provide [Localino] - localize functions.
///
/// Access to [LocalinoDelegate] is handled via static functions.
mixin LocalinoProvider {
  /// Subscription to default global object stream - [ControlBroadcast] with [Localino] key.
  /// Every localization change is send to global broadcast with result of data load.
  ///
  /// [callback] to listen results of locale changes.
  static BroadcastSubscription<LocalinoArgs> subscribe(
          ValueCallback<LocalinoArgs?> callback) =>
      BroadcastProvider.subscribe<LocalinoArgs>(Localino, callback);

  /// Returns instance of [Localino] from [Control] store.
  static Localino get instance => Control.get<Localino>()!;

  /// Shortcut for delegate of default [Localino].
  static LocalinoDelegate get delegate => instance.delegate;

  /// Returns instance of [LocalinoRemote] from [Control] store.
  static LocalinoRemote get remote => Control.get<LocalinoRemote>()!;

  /// Returns instance of [LocalinoRemoteApi] from [Control] store.
  static LocalinoRemoteApi get repo => Control.get<LocalinoRemoteApi>()!;

  /// Delegate of [Localino] for the widget tree that corresponds to the given [context].
  ///
  /// Note: usable only with [LocalizationsDelegate]. If delegate is not specified use [Control.localization] instead.
  static Localino? of(BuildContext context) =>
      Localizations.of<Localino>(context, Localino);

  ///Instance of default [Localino]
  @protected
  Localino get localization => instance;

  ///[Localino.localize]
  @protected
  String localize(String key) => localization.localize(key);

  ///[Localino.localizeOr]
  @protected
  String localizeOr(String key, List<String> alterKeys) =>
      localization.localizeOr(key, alterKeys);

  ///[Localino.localizeFormat]
  @protected
  String localizeFormat(String key, Map<String, String> params) =>
      localization.localizeFormat(key, params);

  ///[Localino.localizePlural]
  @protected
  String localizePlural(String key, int plural,
          [Map<String, String>? params]) =>
      localization.localizePlural(key, plural, params);

  ///[Localino.localizeValue]
  @protected
  String localizeValue(String key, String value) =>
      localization.localizeValue(key, value);

  ///[Localino.localizeList]
  @protected
  Iterable<String> localizeList(String key) => localization.localizeList(key);

  ///[Localino.localizeDynamic]
  @protected
  dynamic localizeDynamic(String key,
          {LocalizationParser? parser, dynamic defaultValue}) =>
      localization.localizeDynamic(key,
          parser: parser, defaultValue: defaultValue);

  ///[Localino.extractLocalization]
  @protected
  String extractLocalization(dynamic data,
          {String? locale, String? defaultLocale}) =>
      localization.extractLocalization(data,
          locale: locale, defaultLocale: defaultLocale);
}
