part of flutter_control;

/// A widget that subscribes to an observable object and rebuilds when the object notifies of a change.
///
/// The [control] object can be of various types, including [ValueListenable],
/// [Listenable], [Stream], [Future], or any [ObservableValue] from the Control framework.
/// See [ControlObservable.of] for a full list of supported types.
class ControlBuilder<T> extends StatefulWidget {
  /// The observable object to subscribe to.
  final dynamic control;

  /// A builder function that is called when the control notifies of a change.
  final ControlWidgetBuilder<T> builder;

  /// An optional builder for the case when the control's value is `null`.
  final WidgetBuilder? noData;

  /// An optional function to convert the control's value to the desired type [T].
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
    // ?AWFUL HACK: default generic Type is Object?
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

/// A widget that subscribes to a list of observable objects and rebuilds when any of them notify of a change.
///
/// Supported observable types are the same as for [ControlBuilder].
class ControlBuilderGroup extends StatefulWidget {
  /// A list of observable objects to subscribe to.
  final List controls;

  /// A builder function that is called when any of the controls notify of a change.
  /// The builder receives a list of the current values from the controls.
  final ControlWidgetBuilder<List?> builder;

  /// If `true`, the builder will receive the list of control objects themselves
  /// instead of their values.
  final bool passControls;

  /// Creates a [ControlBuilderGroup].
  ///
  /// [controls] A list of objects to listen to (e.g., [ActionControl], [ValueListenable]).
  /// [builder] A function that builds the widget based on the latest values from the controls.
  /// [passControls] If true, passes the control objects themselves to the builder instead of their values.
  const ControlBuilderGroup({
    super.key,
    required this.controls,
    required this.builder,
    this.passControls = false,
  });

  @override
  _ControlBuilderGroupState createState() => _ControlBuilderGroupState();
}

/// State for [ControlBuilderGroup].
class _ControlBuilderGroupState extends _ValueState<ControlBuilderGroup, List> {
  /// All active subscriptions.
  final _subs = <Disposable>[];

  final _observables = <ObservableValue>[];

  @override
  void initState() {
    super.initState();

    _initSubs();
  }

  /// Maps the values from the listened controls to a list.
  List _mapValues() {
    if (widget.passControls) {
      return widget.controls;
    }

    return _observables.map((e) => e.value).toList();
  }

  /// Subscribes to all controls in the list.
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

  /// Notifies the state to rebuild and updates the current values.
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

  /// Disposes all active subscriptions.
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
