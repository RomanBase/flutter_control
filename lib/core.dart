library flutter_control;

export 'package:flutter/material.dart';

export 'package:flutter_control/app_control.dart';
export 'package:flutter_control/app_localization.dart';
export 'package:flutter_control/app_base.dart';
export 'package:flutter_control/app_factory.dart';

export 'package:flutter_control/controller/base_controller.dart';
export 'package:flutter_control/controller/field_controller.dart';

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
