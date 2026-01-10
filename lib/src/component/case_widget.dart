part of flutter_control;

/// Showing only one widget by active case.
/// Based on [AnimatedSwitcher].
class CaseWidget<T> extends StatefulWidget {
  /// Currently active case.
  final T? activeCase;

  /// Set of [Widget] builders. Every builder is stored under own case [T] key.
  final Map<T, WidgetBuilder> builders;

  /// Placeholder if [activeCase] is 'null' or not found in [builders].
  final WidgetBuilder? placeholder;

  /// Default transition from one widget to another. By default [CrossTransition.fade] is used.
  final CrossTransition? transition;

  /// Specific [CrossTransition] for every case. If case is not included, then default [transition] is used.
  final Map<T, CrossTransition>? transitions;

  final bool autoKey;

  final bool reverseOrder;

  final bool reverseAnimation;

  final bool soft;

  /// Resolves what to show by [activeCase].
  /// Every [Widget] has custom case [T] key and is build only if case is active.
  /// Only one [Widget] is shown at given time.
  ///
  /// When case is changed [CrossTransition] animation is played between current and next Widget.
  const CaseWidget({
    Key? key,
    required this.activeCase,
    required this.builders,
    this.placeholder,
    this.transition,
    this.transitions,
    this.autoKey = true,
    this.reverseOrder = false,
    this.reverseAnimation = false,
    this.soft = true,
  }) : super(key: key);

  /// A convenience builder for [CaseWidget] that uses a [ControlBuilder] to
  /// listen to a `control` and automatically update the active case.
  static Widget builder<T>({
    Key? key,
    required dynamic control,
    required Map<T, WidgetBuilder> builders,
    WidgetBuilder? placeholder,
    CrossTransition? transition,
    Map<T, CrossTransition>? transitions,
    bool autoKey = true,
    ValueGetter<bool>? reverseOrder,
    ValueGetter<bool>? reverseAnimation,
    T Function(dynamic)? valueConverter,
  }) =>
      ControlBuilder(
        key: key,
        control: control,
        valueConverter: valueConverter,
        builder: (context, value) => CaseWidget<T>(
          activeCase: value as T?,
          builders: builders,
          placeholder: placeholder,
          transition: transition,
          transitions: transitions,
          autoKey: autoKey,
          reverseOrder: reverseOrder?.call() ?? false,
          reverseAnimation: reverseAnimation?.call() ?? false,
        ),
      );

  @override
  _CaseWidgetState createState() => _CaseWidgetState<T>();

  /// Returns transition of [activeCase].
  CrossTransition get activeTransition {
    if (transitions != null && transitions!.containsKey(activeCase)) {
      return transitions![activeCase]!;
    }

    return transition ?? CrossTransition.fade();
  }
}

class _CaseWidgetState<T> extends State<CaseWidget<T>> {
  late Widget currentWidget;

  late CrossTransition currentTransition;

  @override
  void initState() {
    super.initState();

    _updateCurrentWidget();
  }

  @override
  void didUpdateWidget(CaseWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activeCase != oldWidget.activeCase) {
      setState(() {
        _updateCurrentWidget();
      });
    } else if ((context as Element).dirty) {
      _updateCurrentWidget();
    } else if (widget.soft) {
      setState(() {
        _updateCurrentWidget();
      });
    }
  }

  void _updateCurrentWidget() {
    currentTransition = widget.activeTransition;

    if (widget.activeCase != null &&
        widget.builders.containsKey(widget.activeCase)) {
      currentWidget = widget.builders[widget.activeCase]!.call(context);
    } else {
      currentWidget = widget.placeholder?.call(context) ?? Container();
    }

    if (widget.autoKey) {
      currentWidget = KeyedSubtree(
        key: ValueKey(
            ObjectTag.of(this).variant(widget.activeCase ?? UnitId.nextId())),
        child: currentWidget,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: currentTransition.duration,
      reverseDuration:
          currentTransition.reverseDuration ?? currentTransition.duration,
      transitionBuilder:
          currentTransition.build(reverse: widget.reverseAnimation),
      child: currentWidget,
      layoutBuilder: (child, list) => Stack(
        alignment: Alignment.center,
        children: widget.reverseOrder
            ? [
                if (child != null) child,
                ...list,
              ]
            : [
                ...list,
                if (child != null) child,
              ],
      ),
    );
  }
}
