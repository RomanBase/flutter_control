import 'package:flutter_control/core.dart';

/// Lightweight version of Controller. Mainly used for Items in dynamic List or to separate/reuse Logic.
class BaseModel implements Initializable, Disposable {
  /// returns instance of [ControlFactory] if available.
  /// nullable
  ControlFactory get factory => ControlFactory.of(this);

  /// returns instance of [AppControl] if available.
  /// nullable
  AppControl get control => factory.get(FactoryKey.control);

  /// returns instance of [BaseLocalization]
  BaseLocalization get _localization => factory.get(FactoryKey.localization);

  /// Default constructor.
  BaseModel();

  @override
  void init(Map args) {}

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  /// Non null.
  @protected
  String localize(String key) => _localization?.localize(key) ?? '';

  /// Tries to localize text by given key.
  /// Localization is part of AppControl or BaseApp Widget.
  /// Non null.
  @protected
  String extractLocalization(Map field) => _localization?.extractLocalization(field) ?? '';

  @override
  void dispose() {}
}
