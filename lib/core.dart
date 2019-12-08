library flutter_control;

import 'dart:io';

import 'core.dart';

export 'package:flutter/material.dart';

export './src/app_base.dart';
export './src/app_control.dart';
export './src/base_control.dart';
export './src/base_localization.dart';
export './src/base_prefs.dart';
export './src/controller/base_controller.dart';
export './src/controller/base_model.dart';
export './src/controller/field_control.dart';
export './src/controller/route_control.dart';
export './src/entity/menu.dart';
export './src/factory.dart';
export './src/theme_control.dart';
export './src/util/device.dart';
export './src/util/future_block.dart';
export './src/util/init_holder.dart';
export './src/util/parser.dart';
export './src/util/unit_id.dart';
export './src/widget/base_widget.dart';
export './src/widget/input_field.dart';
export './src/widget/navigation_stack.dart';
export './src/widget/stable_widget.dart';
export './src/widget/widget_provider.dart';

class ControlKey {
  static const String factory = 'factory';
  static const String broadcast = 'broadcast';
  static const String localization = 'localization';
  static const String preferences = 'prefs';
  static const String control = 'control';
  static const String initData = 'init_data';
  static const String theme = 'theme';
}

const public_key = Key('public');

bool get debugMode => !inRelease();

bool inRelease({bool profileModeAsRelease: true}) {
  bool result = profileModeAsRelease ? true : bool.fromEnvironment('dart.vm.product'); // profile and release mode

  assert(() {
    result = false; // debug mode
    return true;
  }());

  return result;
}

T onPlatform<T>({
  Initializer<T> android,
  Initializer<T> ios,
  Initializer<T> mobile,
  Initializer<T> mac,
  Initializer<T> win,
  Initializer<T> desktop,
  Initializer<T> all,
  dynamic args,
}) {
  switch (Platform.operatingSystem) {
    case 'android':
      return _platformFuncSwitch(android, mobile, all, args);
    case 'ios':
      return _platformFuncSwitch(ios, mobile, all, args);
    case 'macos':
      return _platformFuncSwitch(mac, desktop, all, args);
    case 'windows':
      return _platformFuncSwitch(win, desktop, all, args);
    case 'linux':
      return _platformFuncSwitch(null, desktop, all, args);
    case 'fuchsia':
      return _platformFuncSwitch(null, desktop, all, args);
    default:
      return all == null ? null : all(args);
  }
}

T _platformFuncSwitch<T>(Initializer<T> platform, Initializer<T> alter, Initializer<T> all, dynamic args) {
  if (platform != null) {
    return platform(args);
  }

  if (alter != null) {
    return alter(args);
  }

  if (all != null) {
    return all(args);
  }

  return null;
}

void printDebug(Object object) {
  if (debugMode) {
    print(object);
  }
}
