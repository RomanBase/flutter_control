part of flutter_control;

/// A specialized [StreamBuilder] for use with a [FieldControl].
///
/// It automatically uses the control's `stream` and `value` for the builder's
/// `stream` and `initialData` properties.
class FieldStreamBuilder<T> extends StreamBuilder<T?> {
  /// Creates a [FieldStreamBuilder].
  ///
  /// [control] The [FieldControl] that provides the data stream.
  /// [builder] A builder that creates a widget based on the [AsyncSnapshot] from the stream.
  FieldStreamBuilder({
    super.key,
    required FieldControl<T> control,
    required AsyncWidgetBuilder<T?> builder,
  }) : super(
          initialData: control.value,
          stream: control.stream,
          builder: builder,
        );

  @override
  Widget build(BuildContext context, AsyncSnapshot<T?> currentSummary) {
    return super.build(context, currentSummary);
  }
}

/// A convenience widget that builds itself based on the state of a [FieldControl].
///
/// It simplifies handling the `snapshot.hasData` case from a [StreamBuilder].
class FieldBuilder<T> extends FieldStreamBuilder<T> {
  /// Creates a [FieldBuilder].
  ///
  /// [control] The [FieldControl] to listen to.
  /// [builder] A builder that is called with the control's value.
  /// [noData] An optional widget to display when the control's value is `null`.
  /// [nullOk] If `true`, the [builder] will be called even with `null` values.
  FieldBuilder({
    super.key,
    required FieldControl<T> control,
    required ControlWidgetBuilder<T?> builder,
    WidgetBuilder? noData,
    bool nullOk = false,
  }) : super(
            control: control,
            builder: (context, snapshot) {
              if (snapshot.hasData || nullOk) {
                return builder(context, snapshot.data);
              }

              if (noData != null) {
                return noData(context);
              }

              return Container();
            });
}

/// A convenience widget that builds itself based on the state of a [FieldControl]
/// containing a [List].
///
/// It simplifies handling the case where the list might be empty.
class ListBuilder<T> extends FieldStreamBuilder<List<T>?> {
  /// Creates a [ListBuilder].
  ///
  /// [control] The [FieldControl] that holds the list.
  /// [builder] A builder that is called with the list.
  /// [noData] An optional widget to display when the list is empty or `null`.
  /// [nullOk] If `true`, the [builder] will be called even with an empty or `null` list.
  ListBuilder({
    super.key,
    required FieldControl<List<T>> control,
    required ControlWidgetBuilder<List<T>> builder,
    WidgetBuilder? noData,
    bool nullOk = false,
  }) : super(
          control: control,
          builder: (context, snapshot) {
            if ((snapshot.hasData && snapshot.data!.length > 0) || nullOk) {
              return builder(context, snapshot.data ?? const []);
            }

            if (noData != null) {
              return noData(context);
            }

            return Container();
          },
        );
}

/// A widget that builds itself based on the [LoadingStatus] of a [LoadingControl].
///
/// It uses a [CaseWidget] internally to display different widgets for each
/// loading state (e.g., progress, done, error).
class LoadingBuilder extends ControllableWidget<LoadingControl> {
  final WidgetBuilder? initial;
  final WidgetBuilder? progress;
  final WidgetBuilder? done;
  final WidgetBuilder? error;
  final WidgetBuilder? outdated;
  final WidgetBuilder? unknown;
  final WidgetBuilder? general;
  final CrossTransition? transition;
  final Map<LoadingStatus, CrossTransition>? transitions;

  /// Creates a [LoadingBuilder].
  ///
  /// Provide a builder for each [LoadingStatus] you want to handle.
  ///
  /// - [control]: The [LoadingControl] to monitor.
  /// - [progress]: A widget to show while loading. Defaults to [CircularProgressIndicator].
  /// - [done]: A widget to show when loading is complete.
  /// - [error]: A widget to show when an error occurs.
  /// - [transition]: The default transition between states. Defaults to [CrossTransition.fadeOutFadeIn].
  LoadingBuilder({
    super.key,
    required super.control,
    this.initial,
    this.progress,
    this.done,
    this.error,
    this.outdated,
    this.unknown,
    this.general,
    this.transition,
    this.transitions,
  });

  @override
  Widget build(BuildContext context) {
    final state = control.value;

    return CaseWidget(
      activeCase: state,
      builders: {
        if (initial != null) LoadingStatus.initial: initial!,
        LoadingStatus.progress:
            progress ?? (context) => Center(child: CircularProgressIndicator()),
        if (done != null) LoadingStatus.done: done!,
        if (error != null) LoadingStatus.error: error!,
        if (outdated != null) LoadingStatus.outdated: outdated!,
        if (unknown != null) LoadingStatus.unknown: unknown!,
      },
      placeholder: general ?? (context) => Container(),
      transition: transition ?? CrossTransition.fadeOutFadeIn(),
      transitions: transitions,
    );
  }
}
