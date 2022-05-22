library flutter_control;

import 'dart:io';
import 'dart:math' as math;

import 'package:control_config/config.dart';
import 'package:control_core/core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:localino/localino.dart';

export 'package:control_config/config.dart';
export 'package:control_core/core.dart';
export 'package:flutter/material.dart';
export 'package:localino/localino.dart';

part 'src/app/control_root.dart';

part 'src/app/device.dart';

part 'src/app/theme_control.dart';

part 'src/component/case_widget.dart';

part 'src/component/input_field.dart';

part 'src/component/loader_widget.dart';

part 'src/component/navigation_stack.dart';

part 'src/control/input_control.dart';

part 'src/control/navigator_stack_control.dart';

part 'src/control/widget_provider.dart';

part 'src/mixin/animation.dart';

part 'src/mixin/control.dart';

part 'src/mixin/layout.dart';

part 'src/mixin/navigation.dart';

part 'src/mixin/overlay.dart';

part 'src/navigator/control_navigator.dart';

part 'src/navigator/route_control.dart';

part 'src/scope.dart';

part 'src/util/curve.dart';

part 'src/util/transition.dart';

part 'src/widget/builder_widget.dart';

part 'src/widget/control_widget.dart';

part 'src/widget/controllable_widget.dart';

part 'src/widget/core_widget.dart';

part 'src/widget/field_builder.dart';

typedef ControlWidgetBuilder<T> = Widget Function(BuildContext context, T value);
typedef InitWidgetBuilder = Widget Function(InitBuilderArgs args);
