library flutter_control;

import 'package:flutter/foundation.dart';

import 'core.dart';

export 'package:flutter/material.dart';

export './src/base_injector.dart';
export './src/base_localization.dart';
export './src/control.dart';
export './src/control/action_control.dart';
export './src/control/control_model.dart';
export './src/control/disposable.dart';
export './src/control/field_control.dart';
export './src/control/observable_group.dart';
export './src/control/route_control.dart';
export './src/control/stack_control.dart';
export './src/control_broadcast.dart';
export './src/theme_control.dart';
export './src/util/args.dart';
export './src/util/base_prefs.dart';
export './src/util/curve.dart';
export './src/util/device.dart';
export './src/util/future_block.dart';
export './src/util/init_holder.dart';
export './src/util/parser.dart';
export './src/util/unit_id.dart';
export './src/widget/builder_widget.dart';
export './src/widget/case_widget.dart';
export './src/widget/control_root.dart';
export './src/widget/control_widget.dart';
export './src/widget/controllable_widget.dart';
export './src/widget/core_widget.dart';
export './src/widget/input_field_v1.dart';
export './src/widget/input_field.dart';
export './src/widget/loader_widget.dart';
export './src/widget/navigation_stack.dart';
export './src/widget/notifier_widget.dart';
export './src/widget/stable_widget.dart';
export './src/widget/statebound_widget.dart';
export './src/widget/transition_holder.dart';
export './src/widget/widget_provider.dart';

enum LoadingStatus { initial, progress, done, error, outdated, unknown }

typedef Initializer<T> = T Function(dynamic args);
typedef ValueCallback<T> = void Function(T value);

typedef ValueConverter<T> = T Function(dynamic value);
typedef EntryConverter<T> = T Function(dynamic key, dynamic value);

typedef ControlWidgetBuilder<T> = Widget Function(
    BuildContext context, T value);
typedef bool Predicate<T>(T value);

void printDebug(Object object) {
  if (kDebugMode && Control.debug) {
    print(object);
  }
}
