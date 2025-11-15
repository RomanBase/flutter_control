part of flutter_control;

extension OverlayControl on CoreContext {
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

  OverlayEntry? getOverlay(dynamic key) =>
      args.get<OverlayEntry>(key: ObjectTag.of(key));

  bool hideOverlay(dynamic key) {
    final overlay = getOverlay(key);

    if (overlay != null) {
      overlay.remove();
      args.remove(key: ObjectTag.of(key));

      return true;
    }

    return false;
  }

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
