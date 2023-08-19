part of flutter_control;

mixin OverlayControl on CoreWidget {
  OverlayEntry? showOverlay({
    required dynamic key,
    required Widget Function(Rect parent) builder,
    GlobalKey? parentKey,
    bool barrierDismissible = true,
  }) {
    assert(isInitialized);

    final overlay = Overlay.of(context!);

    if (holder.argStore.containsKey(ObjectTag.of(key))) {
      return getOverlay(key);
    }

    if (key is GlobalKey && parentKey == null) {
      parentKey = key;
    }

    final box = (parentKey?.currentState?.context.findRenderObject() ??
        context!.findRenderObject()) as RenderBox;
    final location = box.localToGlobal(Offset.zero);
    final size = box.size;

    final child = builder(
        Rect.fromLTWH(location.dx, location.dy, size.width, size.height));

    final entry = OverlayEntry(
      builder: (_) => barrierDismissible
          ? Stack(
              children: [
                GestureDetector(
                  onTap: () => hideOverlay(key),
                ),
                child,
              ],
            )
          : child,
    );

    setArg(key: ObjectTag.of(key), value: entry);

    overlay.insert(entry);

    return entry;
  }

  OverlayEntry? getOverlay(dynamic key) =>
      getArg<OverlayEntry>(key: ObjectTag.of(key));

  bool hideOverlay(dynamic key) {
    final overlay = getOverlay(key);

    if (overlay != null) {
      overlay.remove();
      removeArg(key: ObjectTag.of(key));

      return true;
    }

    return false;
  }

  bool clearOverlays() {
    final items = holder.argStore.getAll<OverlayEntry>();

    if (items.isNotEmpty) {
      items.forEach((element) {
        element.remove();
      });

      holder.argStore.removeAll<OverlayEntry>();

      return true;
    }

    return false;
  }
}
