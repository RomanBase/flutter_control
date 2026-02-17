part of flutter_control;

/// An extension on [CoreContext] to manage [OverlayEntry]s.
extension OverlayControl on CoreContext {
  /// Shows an [OverlayEntry] and associates it with a [key].
  ///
  /// [key] A unique key to identify the overlay.
  /// [builder] A builder function that returns the widget to be displayed in the overlay.
  ///           It receives the bounds of the parent widget.
  /// [parentKey] A [GlobalKey] to identify the parent widget and determine the overlay position.
  /// [parentContext] A [BuildContext] to identify the parent widget. If not provided, `parentKey` is used.
  /// [barrierDismissible] If true, the overlay can be dismissed by tapping outside of it.
  /// Returns the created [OverlayEntry], or `null` if the context is not mounted.
  OverlayEntry? showOverlay({
    required dynamic key,
    required Widget Function(Rect parent) builder,
    GlobalKey? parentKey,
    BuildContext? parentContext,
    bool barrierDismissible = true,
  }) {
    if (!mounted) {
      return null;
    }

    final overlay = Overlay.of(this);

    if (args.containsKey(ObjectTag.of(key))) {
      return getOverlay(key);
    }

    if (key is GlobalKey && parentKey == null) {
      parentKey = key;
    }

    parentContext ??= parentKey?.currentState?.context;

    Widget build() {
      final box = (parentContext?.findRenderObject() ?? findRenderObject())
          as RenderBox?;

      if (box == null) {
        final size = view.viewSize;
        return builder(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
      }

      final location = box.localToGlobal(Offset.zero);
      final size = box.size;

      return builder(
          Rect.fromLTWH(location.dx, location.dy, size.width, size.height));
    }

    final entry = OverlayEntry(
      builder: (_) => barrierDismissible
          ? Stack(
              children: [
                GestureDetector(
                  onTap: () => hideOverlay(key),
                ),
                build(),
              ],
            )
          : build(),
    );

    args.add(key: ObjectTag.of(key), value: entry);

    overlay.insert(entry);

    return entry;
  }

  /// Retrieves an existing [OverlayEntry] by its [key].
  OverlayEntry? getOverlay(dynamic key) =>
      args.get<OverlayEntry>(key: ObjectTag.of(key));

  /// Hides and removes an [OverlayEntry] identified by [key].
  /// Returns `true` if the overlay was found and removed.
  bool hideOverlay(dynamic key) {
    final overlay = getOverlay(key);

    if (overlay != null) {
      overlay.remove();
      args.remove(key: ObjectTag.of(key));

      return true;
    }

    return false;
  }

  /// Removes all overlays managed by this context.
  /// Returns `true` if any overlays were removed.
  bool clearOverlays() {
    final items = args.getAll<OverlayEntry>();

    if (items.isNotEmpty) {
      for (final element in items) {
        element.remove();
      }

      args.removeAll<OverlayEntry>();

      return true;
    }

    return false;
  }
}
