library flutter_control;

import 'dart:io';

import 'package:flutter_control/core.dart';

export 'package:flutter/material.dart';

export 'package:flutter_control/app_control.dart';
export 'package:flutter_control/app_localization.dart';
export 'package:flutter_control/app_base.dart';
export 'package:flutter_control/app_factory.dart';

export 'package:flutter_control/controller/base_controller.dart';
export 'package:flutter_control/controller/field_controller.dart';
export 'package:flutter_control/controller/future_block.dart';

export 'package:flutter_control/util/device.dart';
export 'package:flutter_control/util/handler.dart';

export 'package:flutter_control/widget/action_popup.dart';
export 'package:flutter_control/widget/base_page.dart';
export 'package:flutter_control/widget/base_widget.dart';
export 'package:flutter_control/widget/fade_in.dart';
export 'package:flutter_control/widget/input_field.dart';
export 'package:flutter_control/widget/menu_sheet.dart';
export 'package:flutter_control/widget/navigatioin_stack.dart';

bool get debugMode => !inRelease();

bool inRelease({bool profileModeAsRelease: true}) {
  bool result = profileModeAsRelease ? true : bool.fromEnvironment('dart.vm.product'); // profile and release mode

  assert(() {
    result = false; // debug mode
    return true;
  }());

  return result;
}

T onPlatform<T>({Getter<T> android, Getter<T> ios, Getter<T> all}) {
  switch (Platform.operatingSystem) {
    case 'android':
      return android == null ? (all == null ? null : all()) : android();
    case 'ios':
      return ios == null ? (all == null ? null : all()) : ios();
    default:
      return all == null ? null : all();
  }
}
