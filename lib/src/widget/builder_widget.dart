import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

/// Experimental version of unified [ControlWidgetBuilder].
/// Currently supports [ActionControl], [FieldControl], [Listenable]
//TODO: support [Stream] and [Future] via [FieldControl].
class ControlBuilder<T> extends StatefulWidget {
  /// Control to subscribe.
  final dynamic control;

  /// Widget builder.
  final ControlWidgetBuilder<T> builder;

  /// Widget builder for non value.
  final WidgetBuilder noData;

  /// Checks if 'null' value of [control] is valid for [builder].
  final bool nullOk;

  const ControlBuilder({
    Key key,
    this.control,
    this.builder,
    this.noData,
    this.nullOk: false,
  }) : super(key: key);

  @override
  _ControlBuilderState<T> createState() => _ControlBuilderState<T>();
}

class _ControlBuilderState<T> extends ValueState<ControlBuilder<T>, T> {
  Disposable _sub;

  dynamic get control => widget.control;

  bool get isDirty => (context as Element)?.dirty ?? false;

  T _mapValue() {
    if (T != dynamic && control is T) {
      return control;
    }

    dynamic data;

    if (control is ActionControlObservable) {
      data = control.value;
    } else if (control is FieldControlStream) {
      data = control.value;
    } else if (control is ValueListenable) {
      data = control.value;
    } else {
      data = control;
    }

    return data as T;
  }

  @override
  void initState() {
    super.initState();

    _initSub();
  }

  void _initSub() {
    if (control is ActionControlObservable) {
      _sub = control.subscribe(
        (value) => _notifyState(),
        current: false,
      );
    } else if (control is FieldControlStream) {
      _sub = control.subscribe(
        (value) => _notifyState(),
        current: false,
      );
    } else if (control is Listenable) {
      control.addListener(_notifyState);
    }

    value = _mapValue();
  }

  _notifyState() => notifyValue(_mapValue());

  @override
  void didUpdateWidget(ControlBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (control != oldWidget.control) {
      _disableSub();
      _initSub();
      _notifyState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (value == null && !widget.nullOk) {
      return widget.noData?.call(context) ?? Container();
    }

    return widget.builder(context, value);
  }

  void _disableSub() {
    _sub?.dispose();
    _sub = null;

    if (control is Listenable) {
      control.removeListener(_notifyState);
    }
  }

  @override
  void dispose() {
    super.dispose();

    _disableSub();
  }
}

/// Subscribes to multiple [Stream], [Observable] and [Listenable] objects and listens about changes.
/// Whenever one of [controls] notifies about change, Widget is rebuild.
/// Supports [ActionControl], [FieldControl], [StateControl], [ValueListenable] and [Listenable].
///
/// Check single control Widget for specified version:
///   - [ActionBuilder] for single [ActionControlObservable].
///   - [FieldBuilder] for single [FieldControlStream].
///   - [NotifierBuilder] for single [Listenable].
class ControlBuilderGroup extends StatefulWidget {
  /// List of Controls that will notify this Widget about changes.
  final List controls;

  /// Widget builder.
  /// Builder passes [value] as List of values from given [controls]. If object don't have value (eg. [Listenable]), actual object is returned.
  /// Value order is same as [controls] order.
  final ControlWidgetBuilder<List> builder;

  /// Checks if pass [controls] to [builder] instead of 'values'.
  final bool passControls;

  /// Builds Widget every time when data in [controls] are changed.
  /// [controls] - List of objects that will notifies Widget to rebuild. Supports [ActionControl], [FieldControl], [StateControl], [ValueListenable] and [Listenable].
  /// [builder] - Widget builder, passes [value] as List of values from given [controls].
  /// [passControls] - Passes [controls] to [builder] instead of 'values'.
  const ControlBuilderGroup({
    Key key,
    @required this.controls,
    @required this.builder,
    this.passControls: false,
  }) : super(key: key);

  @override
  _ControlBuilderGroupState createState() => _ControlBuilderGroupState();
}

/// State of [ControlBuilderGroup].
class _ControlBuilderGroupState extends ValueState<ControlBuilderGroup, List> {
  /// All active subs.
  final _subs = List<Disposable>();

  bool get isDirty => (context as Element)?.dirty ?? false;

  @override
  void initState() {
    super.initState();

    value = _mapValues();
    _initSubs();
  }

  /// Maps values from Controls to List.
  List _mapValues() {
    if (widget.passControls) {
      return widget.controls;
    }

    final data = List();

    widget.controls.forEach((control) {
      if (control is ActionControlObservable) {
        data.add(control.value);
      } else if (control is FieldControlStream) {
        data.add(control.value);
      } else if (control is ValueListenable) {
        data.add(control.value);
      } else {
        data.add(control);
      }
    });

    return data;
  }

  /// Subscribes to Controls and listen each about changes.
  void _initSubs() {
    widget.controls.forEach((control) {
      if (control is ActionControlObservable) {
        _subs.add(control.subscribe(
          (value) => _notifyState(),
          current: false,
        ));
      } else if (control is FieldControlStream) {
        _subs.add(control.subscribe(
          (value) => _notifyState(),
          current: false,
        ));
      } else if (control is Listenable) {
        control.addListener(_notifyState);
      }
    });
  }

  /// Notifies State and maps Control values.
  void _notifyState() => notifyValue(_mapValues());

  @override
  void didUpdateWidget(ControlBuilderGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    //TODO: check just controls and re-sub only changes

    _disposeSubs();
    _initSubs();

    List initial = value;
    List current = _mapValues();

    if (initial.length == current.length) {
      for (int i = 0; i < initial.length; i++) {
        if (initial[i] != current[i]) {
          notifyValue(current);
          break;
        }
      }
    } else {
      notifyValue(current);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, value);

  /// Disposes all Subscriptions and Listeners.
  void _disposeSubs() {
    _subs.forEach((item) => item.dispose());
    _subs.clear();

    widget.controls.forEach((control) {
      if (control is Listenable) {
        control.removeListener(_notifyState);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _disposeSubs();
  }
}
