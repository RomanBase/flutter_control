part of flutter_control;

extension ScrollControllerHook on CoreContext {
  _ScrollControllerProvider get scroll => use<_ScrollControllerProvider>(
        value: () => _ScrollControllerProvider(),
        //ScrollController is [ChangeNotifier] - CoreElement will auto dispose this
      )!;
}

class _ScrollControllerProvider extends ScrollController {
  final _scrolls = <dynamic, ScrollController>{};

  operator [](dynamic key) => this(key);

  ScrollController call(
    dynamic key, {
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    ScrollControllerCallback? onAttach,
    ScrollControllerCallback? onDetach,
  }) {
    if (!_scrolls.containsKey(key)) {
      _scrolls[key] = ScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        onAttach: onAttach,
        onDetach: onDetach,
      );
    }

    return _scrolls[key]!;
  }

  @override
  void dispose() {
    super.dispose();

    _scrolls.forEach((key, value) => value.dispose());
  }
}
