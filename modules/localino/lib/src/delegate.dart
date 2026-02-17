part of localino;

/// Delegate of [Localino] to use with [LocalizationsDelegate].
///
/// Use [LocalizationProvider.of(context)] to find delegate in the widget tree that corresponds to the given [context].
class LocalinoDelegate extends LocalizationsDelegate<Localino> {
  /// Localization to work with.
  final Localino localization;

  /// Creates delegate of [Localino].
  ///
  /// Typically this constructor is not called directly, but instance of delegate is created with [Localino.delegate].
  LocalinoDelegate(this.localization);

  /// Active locale of [Localino].
  ///
  /// Returns [Localino.getLocale].
  Locale? get locale => localization.getLocale(localization.locale);

  @override
  bool isSupported(Locale locale) =>
      localization.isLocalizationAvailable(locale.toString());

  @override
  Future<Localino> load(Locale locale) async {
    await localization.changeLocale(locale.toString());

    return localization;
  }

  @override
  bool shouldReload(LocalizationsDelegate old) => false;

  /// Returns list of supported locales from [Localino] assets.
  /// If no assets are provided, then system locales are returned.
  List<Locale> supportedLocales() {
    final list = <Locale>[];

    localization._assets.forEach((asset) {
      list.add(asset.toLocale());
    });

    return list.isEmpty ? WidgetsBinding.instance.window.locales : list;
  }
}
