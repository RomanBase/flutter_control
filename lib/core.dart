library flutter_control;

import 'dart:io';

import 'core.dart';

export 'package:flutter/material.dart';

export './src/app_base.dart';
export './src/app_control.dart';
export './src/base_localization.dart';
export './src/base_prefs.dart';
export './src/base_theme.dart';
export './src/controller/base_controller.dart';
export './src/controller/base_model.dart';
export './src/controller/field_control.dart';
export './src/entity/menu.dart';
export './src/factory.dart';
export './src/util/device.dart';
export './src/util/future_block.dart';
export './src/util/init_holder.dart';
export './src/util/parser.dart';
export './src/widget/base_widget.dart';
export './src/widget/input_field.dart';
export './src/widget/navigation_stack.dart';
export './src/widget/stable_widget.dart';
export './src/widget/widget_provider.dart';

class ControlKey {
  static const String factory = 'factory';
  static const String localization = 'localization';
  static const String preferences = 'prefs';
  static const String control = 'control';
}

bool get debugMode => !inRelease();

bool inRelease({bool profileModeAsRelease: true}) {
  bool result = profileModeAsRelease ? true : bool.fromEnvironment('dart.vm.product'); // profile and release mode

  assert(() {
    result = false; // debug mode
    return true;
  }());

  return result;
}

T onPlatform<T>({Initializer<T> android, Initializer<T> ios, Initializer<T> all}) {
  switch (Platform.operatingSystem) {
    case 'android':
      return android == null ? (all == null ? null : all()) : android();
    case 'ios':
      return ios == null ? (all == null ? null : all()) : ios();
    default:
      return all == null ? null : all();
  }
}

void printDebug(Object object) {
  if (debugMode) {
    print(object);
  }
}
