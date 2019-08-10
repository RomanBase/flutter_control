import 'package:flutter_control/core.dart';

/// Lightweight version of Controller. Mainly used for Items in dynamic List or to separate/reuse Logic.
/// Mixin your model with [LocalizationProvider] to enable localization.
class BaseModel implements Initializable, Disposable {
  /// returns instance of [ControlFactory] if available.
  /// nullable
  ControlFactory get factory => ControlFactory.of(this);

  /// returns instance of [AppControl] if available.
  /// nullable
  AppControl get control => factory.get(ControlKey.control);

  /// Default constructor.
  BaseModel();

  @override
  void init(Map args) {}

  @override
  void dispose() {}
}
