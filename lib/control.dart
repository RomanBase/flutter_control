library flutter_control;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter_control/control.dart';
import 'package:flutter_control/src/hook/control_hook.dart';

export 'package:control_config/config.dart';
export 'package:control_core/core.dart';
export 'package:flutter/material.dart';
export 'package:flutter/cupertino.dart' hide RefreshCallback;

part 'src/app/app_state.dart';

part 'src/app/control_root.dart';

part 'src/app/device.dart';

part 'src/app/theme_control.dart';

part 'src/component/case_widget.dart';

part 'src/component/loader_widget.dart';

part 'src/component/input_control.dart';

part 'src/hook/animation_controller.dart';

part 'src/hook/context.dart';

part 'src/hook/scroll_controller.dart';

part 'src/hook/theme_data.dart';

part 'src/hook/ticker.dart';

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

part 'src/widget/core/core_element.dart';

part 'src/widget/core/core_state.dart';

part 'src/widget/core/core_widget.dart';

part 'src/widget/builder_widget.dart';

part 'src/widget/control_widget.dart';

part 'src/widget/controllable_widget.dart';

part 'src/widget/field_builder.dart';

typedef ControlWidgetBuilder<T> = Widget Function(
    BuildContext context, T value);
