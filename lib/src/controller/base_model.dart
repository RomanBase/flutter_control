import 'package:flutter_control/core.dart';

/// Lightweight version of Controller. Mainly used for Items in dynamic List or to separate/reuse Logic.
/// Mixin your model with [LocalizationProvider] to enable localization.
class BaseModel extends BaseControlModel {
  @override
  bool get preferSoftDispose => true;

  /// Default constructor.
  BaseModel();
}
