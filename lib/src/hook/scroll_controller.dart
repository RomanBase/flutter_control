part of flutter_control;

/// Extension hook on [CoreContext] to provide easy access to [ScrollController]s.
extension ScrollControllerHook on CoreContext {
  /// Provides a [_ScrollControllerProvider] for creating and managing [ScrollController] instances.
  ///
  /// The provider is hooked to the [CoreContext] lifecycle and will be disposed automatically.
  _ScrollControllerProvider get scroll => use<_ScrollControllerProvider>(
        value: () => _ScrollControllerProvider(),
        //ScrollController is [ChangeNotifier] - CoreElement will auto dispose this
      );
}

/// A provider class that manages a collection of [ScrollController]s.
/// It allows creating multiple controllers identified by a key.
class _ScrollControllerProvider extends ScrollController {
  /// A map to store the created [ScrollController]s.
  final _scrolls = <dynamic, ScrollController>{};

  /// Provides a [ScrollController] by key.
  operator [](dynamic key) => this(key);

  /// Retrieves or creates a [ScrollController].
  ///
  /// If a controller for the given [key] does not exist, a new one is created.
  ///
  /// [key] A unique identifier for the controller.
  /// [initialScrollOffset] The initial scroll offset.
  /// [keepScrollOffset] Whether to keep the scroll offset.
  /// [onAttach] A callback for when the controller is attached to a scroll view.
  /// [onDetach] A callback for when the controller is detached from a scroll view.
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
