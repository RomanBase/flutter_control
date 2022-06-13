part of flutter_control;

/// Extends [StreamBuilder] and adds some functionality to be used easily with [FieldControl].
/// If no [Widget] is [build] then empty [Container] is returned.
class FieldStreamBuilder<T> extends StreamBuilder<T?> {
  /// Stream based Widget builder. Listening [FieldControlStream.stream] about changes.
  /// [control] - required Stream controller. [FieldControl] or [FieldControlSub].
  /// [builder] - required Widget builder. [AsyncSnapshot] is passing data to handle.
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

/// Extended [FieldStreamBuilder] providing data check above [AsyncSnapshot] and calling corresponding build function.
class FieldBuilder<T> extends FieldStreamBuilder<T> {
  /// Stream based Widget builder. Listening [FieldControlStream.stream] about changes.
  /// [control] - required Stream controller. [FieldControl] or [FieldControlSub].
  /// [builder] - required Widget builder. Non 'null' [T] value is passed directly.
  /// [noData] - Widget to show, when value is 'null'.
  /// [nullOk] - Determine where to handle 'null' values. 'true' - 'null' will be passed to [builder].
  FieldBuilder({
    super.key,
    required FieldControl<T> control,
    required ControlWidgetBuilder<T?> builder,
    WidgetBuilder? noData,
    bool nullOk: false,
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

/// Extended [FieldStreamBuilder] providing data check above [AsyncSnapshot] and calling corresponding build function.
class ListBuilder<T> extends FieldStreamBuilder<List<T>?> {
  /// Stream based Widget builder. Listening [FieldControlStream.stream] about changes.
  /// [control] - required Stream controller. [FieldControl] or [FieldControlSub].
  /// [builder] - required Widget builder. Only non empty [List] is passed directly to handle.
  /// [noData] - Widget to show, when List is empty.
  /// [nullOk] - Determine where to handle empty List. 'true' - empty List will be passed to [builder].
  ListBuilder({
    super.key,
    required FieldControl<List<T>> control,
    required ControlWidgetBuilder<List<T>> builder,
    WidgetBuilder? noData,
    bool nullOk: false,
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

/// Extended [FieldStreamBuilder] version specified to build [LoadingStatus] states.
/// Internally uses [CaseWidget] to animate Widget crossing.
class LoadingBuilder extends FieldStreamBuilder<LoadingStatus?> {
  /// Builds Widget based on current [LoadingStatus].
  /// Uses [CaseWidget] to handle current state and Widget animation.
  ///
  /// [initial] - Initial Widget before loading starts (barely used).
  /// [progress] - Loading Widget, by default [CircularProgressIndicator] is build.
  /// [done] - Widget when loading is completed.
  /// [error] - Error Widget, by default [Text] with [LoadingControl.message] is build.
  /// [outdated], [unknown] - Mostly same as [done] with some badge.
  /// [transition] - Transition between Widgets. By default [CrossTransitions.fadeOutFadeIn] is used.
  /// [transitions] - Case specific transitions.
  ///
  ///  If status don't have default builder, empty [Container] is build.
  ///  'null' is considered as [LoadingStatus.initial].
  LoadingBuilder({
    super.key,
    required LoadingControl control,
    WidgetBuilder? initial,
    WidgetBuilder? progress,
    WidgetBuilder? done,
    WidgetBuilder? error,
    WidgetBuilder? outdated,
    WidgetBuilder? unknown,
    WidgetBuilder? general,
    CrossTransition? transition,
    Map<LoadingStatus, CrossTransition>? transitions,
  }) : super(
          control: control,
          builder: (context, snapshot) {
            final state =
                snapshot.hasData ? snapshot.data : LoadingStatus.initial;

            return CaseWidget(
              activeCase: state,
              builders: {
                if (initial != null) LoadingStatus.initial: initial,
                LoadingStatus.progress: progress ??
                    (context) => Center(child: CircularProgressIndicator()),
                if (done != null) LoadingStatus.done: done,
                if (error != null) LoadingStatus.error: error,
                if (outdated != null) LoadingStatus.outdated: outdated,
                if (unknown != null) LoadingStatus.unknown: unknown,
              },
              placeholder: general ?? (context) => Container(),
              transition: CrossTransition.fadeOutFadeIn(),
              transitions: transitions,
            );
          },
        );
}
