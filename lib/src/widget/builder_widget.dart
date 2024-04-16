part of flutter_control;

/// Subscribes to given [control] and notifies [builder] when object changes.
/// [control] object is typically: [ObservableValue] like [ActionControl] or [ObservableComponent], [FieldControl], [ValueListenable], [Listenable], [Stream] and [Future].
class ControlBuilder<T> extends StatefulWidget {
  /// Control to subscribe.
  final dynamic control;

  /// Widget builder.
  final ControlWidgetBuilder<T> builder;

  /// Widget builder for non value.
  final WidgetBuilder? noData;

  final T Function(dynamic)? valueConverter;

  const ControlBuilder({
    super.key,
    required this.control,
    required this.builder,
    this.noData,
    this.valueConverter,
  });

  @override
  _ControlBuilderState<T> createState() => _ControlBuilderState<T>();
}

class _ControlBuilderState<T> extends _ValueState<ControlBuilder<T>, T> {
  Disposable? _sub;

  ObservableValue<dynamic>? _observable;

  bool isTypeSet = true;

  T? _mapValue() {
    dynamic val;

    if (_observable != null && (_observable!.value is T || T == dynamic)) {
      val = _observable!.value;
    } else if (widget.control is T) {
      val = widget.control;
    }

    if (val == null && !isTypeSet) {
      val = _observable?.value ?? widget.control;
    }

    if (widget.valueConverter != null) {
      val = widget.valueConverter!.call(val ?? _observable?.value);
    }

    return val as T?;
  }

  @override
  void initState() {
    super.initState();

    // [TODO]: do something about it
    // AWFUL HACK: for unknown reason default generic Type is Object? instead of dynamic
    isTypeSet = '$T' != 'Object?' && T != dynamic;

    _initSub();
  }

  void _initSub() {
    _observable = ControlObservable.of<dynamic>(widget.control);

    if (widget.control != _observable) {
      // Mark for Dispose if observable is not same as [widget.control].
      _observable!.internalData = DisposeMarker;
    }

    _sub = _observable!.subscribe(
      (value) => _notifyState(),
      current: false,
    );

    value = _mapValue();
  }

  _notifyState() => notifyValue(_mapValue());

  @override
  void didUpdateWidget(ControlBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.control != oldWidget.control) {
      _disableSub();
      _disableObservable();
      _initSub();
      _notifyState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return widget.noData?.call(context) ?? Container();
    }

    return widget.builder(context, value!);
  }

  void _disableSub() {
    _sub?.dispose();
    _sub = null;
  }

  void _disableObservable() {
    if (_observable?.internalData == DisposeMarker) {
      DisposeHandler.disposeOf(_observable, this);
    }

    _observable = null;
  }

  @override
  void dispose() {
    super.dispose();

    _disableSub();
    _disableObservable();
  }
}

/// Subscribes to multiple [Stream], [Observable] and [Listenable] objects and listens about changes.
/// Whenever one of [controls] notifies about change, Widget is rebuild.
/// Supports [ControlObservable] - [ActionControl], [FieldControl], [ValueListenable], [Listenable], [Stream] and [Future].
class ControlBuilderGroup extends StatefulWidget {
  /// List of Controls that will notify this Widget about changes.
  final List controls;

  /// Widget builder.
  /// Builder passes [value] as List of values from given [controls]. If object don't have value (eg. [Listenable]), actual object is returned.
  /// Value order is same as [controls] order.
  final ControlWidgetBuilder<List?> builder;

  /// Checks if pass [controls] to [builder] instead of 'values'.
  final bool passControls;

  /// Builds Widget every time when data in [controls] are changed.
  /// [controls] - List of objects that will notifies Widget to rebuild. Supports [ActionControl], [FieldControl], [StateControl], [ValueListenable] and [Listenable].
  /// [builder] - Widget builder, passes [value] as List of values from given [controls].
  /// [passControls] - Passes [controls] to [builder] instead of 'values'.
  const ControlBuilderGroup({
    super.key,
    required this.controls,
    required this.builder,
    this.passControls = false,
  });

  @override
  _ControlBuilderGroupState createState() => _ControlBuilderGroupState();
}

/// State of [ControlBuilderGroup].
class _ControlBuilderGroupState extends _ValueState<ControlBuilderGroup, List> {
  /// All active subs.
  final _subs = <Disposable>[];

  final _observables = <ObservableValue>[];

  @override
  void initState() {
    super.initState();

    _initSubs();
  }

  /// Maps values from Controls to List.
  List _mapValues() {
    if (widget.passControls) {
      return widget.controls;
    }

    return _observables.map((e) => e.value).toList();
  }

  /// Subscribes to Controls and listen each about changes.
  void _initSubs() {
    widget.controls.forEach((control) {
      final observable = ControlObservable.of(control);
      if (control != observable) {
        // Mark for Dispose if observable is not same as [widget.control].
        observable.internalData = DisposeMarker;
      }

      _observables.add(observable);
      _subs.add(observable.subscribe(
        (value) => _notifyState(),
        current: false,
      ));
    });

    value = _mapValues();
  }

  /// Notifies State and maps Control values.
  void _notifyState() => notifyValue(_mapValues());

  @override
  void didUpdateWidget(ControlBuilderGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    //TODO: check just controls and re-sub only changes

    _disposeSubs();
    _disableObservables();
    _initSubs();

    List initial = value!;
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
  }

  void _disableObservables() {
    _observables.forEach((element) {
      if (element.internalData == DisposeMarker) {
        DisposeHandler.disposeOf(element, this);
      }
    });

    _observables.clear();
  }

  @override
  void dispose() {
    super.dispose();

    _disposeSubs();
  }
}

abstract class _ValueState<T extends StatefulWidget, U> extends State<T> {
  /// Checks if [Element] is 'mounted' or 'dirty' and marked for rebuild.
  bool get isDirty => !mounted || ((context as Element).dirty);

  /// Current value of state.
  U? value;

  void notifyValue(U? value) {
    if (isDirty) {
      this.value = value;
    } else {
      setState(() {
        this.value = value;
      });
    }
  }
}
