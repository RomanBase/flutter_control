library flutter_control;

import 'package:flutter/foundation.dart';

import 'core.dart';

export 'package:flutter/material.dart';

export 'src/base_injector.dart';
export 'src/base_localization.dart';
export 'src/control.dart';
export 'src/control/action_control.dart';
export 'src/control/control_model.dart';
export 'src/control/disposable.dart';
export 'src/control/field_control.dart';
export 'src/control/observable_component.dart';
export 'src/control/stack_control.dart';
export 'src/control_broadcast.dart';
export 'src/navigator/control_navigator.dart';
export 'src/navigator/route_control.dart';
export 'src/object_tag.dart';
export 'src/observable/control_observable.dart';
export 'src/observable/control_subscription.dart';
export 'src/observable/observable_group.dart';
export 'src/observable/observable_helpers.dart';
export 'src/theme_control.dart';
export 'src/util/args.dart';
export 'src/util/base_prefs.dart';
export 'src/util/curve.dart';
export 'src/util/device.dart';
export 'src/util/future_block.dart';
export 'src/util/lazy_initializer.dart';
export 'src/util/parser.dart';
export 'src/util/unit_id.dart';
export 'src/widget/app/control_root.dart';
export 'src/widget/app/transition.dart';
export 'src/widget/builder_widget.dart';
export 'src/widget/component/case_widget.dart';
export 'src/widget/component/input_field.dart';
export 'src/widget/component/loader_widget.dart';
export 'src/widget/component/navigation_stack.dart';
export 'src/widget/control/input_control.dart';
export 'src/widget/control/navigator_stack_control.dart';
export 'src/widget/control/widget_provider.dart';
export 'src/widget/control_widget.dart';
export 'src/widget/controllable_widget.dart';
export 'src/widget/core_widget.dart';
export 'src/widget/field_builder.dart';
export 'src/widget/mixin/animation.dart';
export 'src/widget/mixin/control.dart';
export 'src/widget/mixin/layout.dart';
export 'src/widget/mixin/navigation.dart';

enum LoadingStatus {
  initial,
  progress,
  done,
  error,
  outdated,
  unknown,
}

typedef Initializer<T> = T Function(dynamic args);
typedef ValueCallback<T> = void Function(T value);

typedef ValueConverter<T> = T Function(dynamic value);
typedef EntryConverter<T> = T Function(dynamic key, dynamic value);

typedef ControlWidgetBuilder<T> = Widget Function(
    BuildContext context, T value);
typedef bool Predicate<T>(T value);

void printDebug(dynamic object) {
  if (kDebugMode && Control.debug && object != null) {
    print(object);
  }
}

void printAction(ValueGetter<dynamic> action) {
  if (kDebugMode && Control.debug) {
    print(action());
  }
}
