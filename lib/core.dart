library flutter_control;

import 'package:flutter/foundation.dart';

import 'core.dart';

export 'package:flutter/material.dart';

export 'src/base_localization.dart';
export 'src/base_prefs.dart';
export 'src/core/base_injector.dart';
export 'src/core/control.dart';
export 'src/core/control/action_control.dart';
export 'src/core/control/control_model.dart';
export 'src/core/control/disposable.dart';
export 'src/core/control/field_control.dart';
export 'src/core/control/observable_component.dart';
export 'src/core/control/stack_control.dart';
export 'src/core/control_broadcast.dart';
export 'src/core/module.dart';
export 'src/core/object_tag.dart';
export 'src/core/observable/control_observable.dart';
export 'src/core/observable/control_subscription.dart';
export 'src/core/observable/observable_group.dart';
export 'src/core/observable/observable_helpers.dart';
export 'src/core/util/args.dart';
export 'src/core/util/assets.dart';
export 'src/core/util/curve.dart';
export 'src/core/util/future_block.dart';
export 'src/core/util/lazy_initializer.dart';
export 'src/core/util/parser.dart';
export 'src/core/util/unit_id.dart';
export 'src/ui/app/control_root.dart';
export 'src/ui/app/device.dart';
export 'src/ui/app/theme_control.dart';
export 'src/ui/app/transition.dart';
export 'src/ui/component/case_widget.dart';
export 'src/ui/component/input_field.dart';
export 'src/ui/component/loader_widget.dart';
export 'src/ui/component/navigation_stack.dart';
export 'src/ui/control/input_control.dart';
export 'src/ui/control/navigator_stack_control.dart';
export 'src/ui/control/widget_provider.dart';
export 'src/ui/mixin/animation.dart';
export 'src/ui/mixin/control.dart';
export 'src/ui/mixin/layout.dart';
export 'src/ui/mixin/navigation.dart';
export 'src/ui/mixin/overlay.dart';
export 'src/ui/navigator/control_navigator.dart';
export 'src/ui/navigator/route_control.dart';
export 'src/ui/scope.dart';
export 'src/ui/widget/builder_widget.dart';
export 'src/ui/widget/control_widget.dart';
export 'src/ui/widget/controllable_widget.dart';
export 'src/ui/widget/core_widget.dart';
export 'src/ui/widget/field_builder.dart';

typedef Initializer<T> = T Function(dynamic args);
typedef ValueCallback<T> = void Function(T value);

typedef ValueConverter<T> = T Function(dynamic value);
typedef EntryConverter<T> = T Function(dynamic key, dynamic value);

typedef ControlWidgetBuilder<T> = Widget Function(
    BuildContext context, T value);
typedef InitWidgetBuilder = Widget Function(InitBuilderArgs args);

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
