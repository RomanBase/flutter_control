library flutter_control;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter_control/control.dart';

export 'package:control_config/config.dart';
export 'package:control_core/core.dart';
export 'package:flutter/material.dart';
export 'package:flutter/cupertino.dart' hide RefreshCallback;

part 'src/app/app_state.dart';

part 'src/app/control_root.dart';

part 'src/app/device.dart';

part 'src/app/theme_control.dart';

part 'src/component/case_widget.dart';

part 'src/component/input_field.dart';

part 'src/component/loader_widget.dart';

part 'src/component/navigation_stack.dart';

part 'src/control/input_control.dart';

part 'src/control/navigator_stack_control.dart';

part 'src/component/ticker_component.dart';

part 'src/component/context_component.dart';

part 'src/component/layout.dart';

part 'src/component/overlay.dart';

part 'src/navigator/control_navigator.dart';

part 'src/navigator/route_control.dart';

part 'src/navigator/route_handler.dart';

part 'src/navigator/route_navigator_extension.dart';

part 'src/navigator/route_store.dart';

part 'src/scope.dart';

part 'src/util/interval_curve.dart';

part 'src/component/cross_transition.dart';

part 'src/widget/builder_widget.dart';

part 'src/widget/control_widget.dart';

part 'src/widget/controllable_widget.dart';

part 'src/widget/core_widget.dart';

part 'src/widget/field_builder.dart';

typedef ControlWidgetBuilder<T> = Widget Function(
    BuildContext context, T value);
