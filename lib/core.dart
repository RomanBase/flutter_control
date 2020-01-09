library flutter_control;

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'core.dart';

export 'package:flutter/material.dart';

export './src/base_localization.dart';
export './src/base_prefs.dart';
export './src/control.dart';
export './src/control_base.dart';
export './src/control_broadcast.dart';
export './src/controller/action_control.dart';
export './src/controller/base_model.dart';
export './src/controller/control_model.dart';
export './src/controller/disposable.dart';
export './src/controller/field_control.dart';
export './src/controller/route_control.dart';
export './src/theme_control.dart';
export './src/util/args.dart';
export './src/util/device.dart';
export './src/util/future_block.dart';
export './src/util/init_holder.dart';
export './src/util/parser.dart';
export './src/util/unit_id.dart';
export './src/widget/control_widget.dart';
export './src/widget/input_field.dart';
export './src/widget/loader_widget.dart';
export './src/widget/navigation_stack.dart';
export './src/widget/notifier_widget.dart';
export './src/widget/stable_widget.dart';
export './src/widget/widget_provider.dart';

enum DialogType { popup, sheet, dialog, dock }

enum LoadingStatus { none, progress, done, error, outdated, unknown }

typedef Initializer<T> = T Function(dynamic args);
typedef ValueCallback<T> = void Function(T value);

typedef ValueConverter<T> = T Function(dynamic value);
typedef EntryConverter<T> = T Function(dynamic key, dynamic value);

typedef ControlWidgetBuilder<T> = Widget Function(BuildContext context, T value);
typedef bool Predicate<T>(T value);

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
  if (kDebugMode && Control.debug) {
    print(object);
  }
}
