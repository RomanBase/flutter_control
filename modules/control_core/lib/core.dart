library control_core;

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

export 'package:flutter/foundation.dart';

part 'src/broadcast.dart';

part 'src/control.dart';

part 'src/control/action_control.dart';

part 'src/control/control_model.dart';

part 'src/control/disposable.dart';

part 'src/control/field_control.dart';

part 'src/control/observable_component.dart';

part 'src/control/stack_control.dart';

part 'src/injector.dart';

part 'src/module.dart';

part 'src/object_tag.dart';

part 'src/observable/control_observable.dart';

part 'src/observable/control_subscription.dart';

part 'src/observable/observable_group.dart';

part 'src/observable/observable_helpers.dart';

part 'src/util/args.dart';

part 'src/util/assets.dart';

part 'src/util/future_block.dart';

part 'src/util/lazy_initializer.dart';

part 'src/util/parser.dart';

part 'src/util/unit_id.dart';

typedef Initializer<T> = T Function(Object? args);
typedef ValueCallback<T> = void Function(T value);

typedef ValueConverter<T> = T Function(dynamic value);
typedef EntryConverter<T> = T Function(Object key, dynamic value);

typedef Predicate<T> = bool Function(T value);

void printDebug(dynamic object) {
  if (Control.debug && object != null) {
    print(object);
  }
}

void printAction(ValueGetter<dynamic> action) {
  if (Control.debug) {
    print(action());
  }
}
