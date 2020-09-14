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

  final WidgetBuilder noData;

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

class _ControlBuilderState<T> extends State<ControlBuilder<T>> {
  Disposable _sub;

  T _value;

  dynamic get control => widget.control;

  T _mapValue() {
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

    _value = _mapValue();
  }

  @override
  void didUpdateWidget(ControlBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (control != oldWidget.control) {
      _disableSub();
      _initSub();
      _notifyState();
    }
  }

  void _notifyState() {
    setState(() {
      _value = _mapValue();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_value == null) {
      return widget.noData?.call(context) ?? Container();
    }

    return widget.builder(context, _value);
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
/// Check single control Widget check specified versions:
///   - [ActionBuilder] for single [ActionControlObservable].
///   - [FieldBuilder] for single [FieldControlStream].
///   - [NotifierBuilder] for single [Listenable].
class ControlBuilderGroup extends StatefulWidget {
  /// List of Controls that will notify this Widget about changes.
  final List<dynamic> controls;

  /// Widget builder.
  /// Builder passes [value] as List of values from given [controls]. If object don't have value (eg. [Listenable]), actual object is returned.
  /// Value order is same as [controls] order.
  final ControlWidgetBuilder<List> builder;

  /// Builds Widget every time when data in [controls] are changed.
  /// [controls] - List of objects that will notifies Widget to rebuild. Supports [ActionControl], [FieldControl], [StateControl], [ValueListenable] and [Listenable].
  /// [builder] - Widget builder, passes [value] as List of values from given [controls].
  const ControlBuilderGroup({
    Key key,
    @required this.controls,
    @required this.builder,
  }) : super(key: key);

  @override
  _ControlBuilderGroupState createState() => _ControlBuilderGroupState();
}

/// State of [ControlBuilderGroup].
class _ControlBuilderGroupState extends State<ControlBuilderGroup> {
  /// Current values.
  List _values;

  /// All active subs.
  final _subs = List<Disposable>();

  @override
  void initState() {
    super.initState();

    _values = _mapValues();
    _initSubs();
  }

  /// Maps values from Controls to List.
  List _mapValues() {
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
  void _notifyState() {
    setState(() {
      _values = _mapValues();
    });
  }

  @override
  void didUpdateWidget(ControlBuilderGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    //TODO: check just controls and re-sub only changes

    _disposeSubs();
    _initSubs();

    List initial = _values;
    List current = _mapValues();

    if (initial.length == current.length) {
      for (int i = 0; i < initial.length; i++) {
        if (initial[i] != current[i]) {
          setState(() {
            _values = current;
          });
          break;
        }
      }
    } else {
      setState(() {
        _values = current;
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _values);

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
