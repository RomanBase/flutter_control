import 'package:flutter_control/core.dart';

/// Showing only one widget by active case.
class CaseWidget<T> extends StatefulWidget {
  /// Currently active case.
  final T activeCase;

  /// Set of [Widget] builders. Every builder is stored under case [T] key.
  final Map<T, WidgetBuilder> builders;

  /// Arguments to pass to [Widget] during initialization.
  final dynamic args;

  /// Placeholder if [activeCase] is null or not found in [builders].
  final WidgetBuilder placeholder;

  /// Default transition from one widget to another. By default [CrossTransitions.fadeCross] is used.
  final CrossTransition transition;

  /// Specific [CrossTransition] for every case. If case is not included, then default [transition] is used.
  final Map<T, CrossTransition> transitions;

  /// Resolves what to show by [activeCase].
  /// Every [Widget] has custom case [T] key and is build only if case is active.
  /// Only one [Widget] is shown at given time.
  ///
  /// When case is changed [CrossTransition] animation is played between current and next Widget.
  const CaseWidget({
    Key key,
    @required this.activeCase,
    @required this.builders,
    this.args,
    this.placeholder,
    this.transition,
    this.transitions,
  }) : super(key: key);

  @override
  _CaseWidgetState createState() => _CaseWidgetState();

  /// Returns transition for [activeCase].
  CrossTransition get activeTransitionIn {
    if (transitions != null && transitions.containsKey(activeCase)) {
      return transitions[activeCase];
    }

    return transition;
  }
}

class _CaseWidgetState extends State<CaseWidget> {
  /// Control for [TransitionHolder].
  /// Handles transition progress and animations.
  final control = TransitionControl()
    ..autoCrossIn(from: 1.0) // cross automatically
    ..initialProgress = 1.0; // start at first case

  /// Previous initializer / already builder Widget.
  /// Widget that's going to be hide.
  WidgetInitializer oldInitializer;

  /// Currently active initializer / next Widget to build.
  /// Widget that's going to be shown.
  WidgetInitializer currentInitializer;

  /// Filtered builders of [CaseWidget.builders]. Null builders are filtered out..
  Map builders;

  @override
  void initState() {
    super.initState();

    builders = widget.builders.fill();
    _updateInitializer();
  }

  @override
  void didUpdateWidget(CaseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    builders = widget.builders.fill();

    if (widget.activeCase != oldWidget.activeCase) {
      setState(() {
        control.initialProgress = 0.0;
        control.autoCrossIn(from: 0.0);
        _updateInitializer();
      });
    } else if (!control.running) {
      setState(() {
        control.initialProgress = 1.0; //ensure to stay on current case
      });
    }
  }

  /// Swaps current / old initializer or builds placeholder if case is not found.
  void _updateInitializer() {
    oldInitializer = currentInitializer;

    if (widget.activeCase != null && builders.containsKey(widget.activeCase)) {
      final builder = builders[widget.activeCase];

      currentInitializer = WidgetInitializer.of(builder);
    } else {
      printDebug('case not found - ${widget.activeCase}');
      currentInitializer = WidgetInitializer.of(_placeholder());
    }

    currentInitializer.key = GlobalKey();

    if (oldInitializer == null) {
      oldInitializer = WidgetInitializer.of(_placeholder());
      oldInitializer.key = GlobalKey();
    }
  }

  /// Checks if is necessary to rebuild current Widget.
  void _updateCurrentInitializer() {
    if (currentInitializer != null &&
        widget.activeCase != null &&
        builders.containsKey(widget.activeCase)) {
      final builder = builders[widget.activeCase];
      final origin = currentInitializer;

      currentInitializer = WidgetInitializer.of(builder);
      currentInitializer.key = origin.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TransitionHolder(
      control: control,
      args: widget.args,
      firstWidget: oldInitializer,
      secondWidget: currentInitializer,
      transitionIn: widget.activeTransitionIn,
    );
  }

  /// Builds placeholder.
  /// If no placeholder is provided and [Control.debug] is active than error placeholder is shown. Empty [Container] is build otherwise.
  WidgetBuilder _placeholder() {
    if (widget.placeholder != null) {
      return widget.placeholder;
    }

    if (widget.activeCase != null && Control.debug) {
      return (_) => Container(
            color: Colors.red,
            child: Center(
              child: Text(
                widget.activeCase.toString(),
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          );
    }

    return (_) => Container();
  }

  @override
  void dispose() {
    super.dispose();

    if (control.isInitialized) {
      control.dispose();
    }
  }
}
