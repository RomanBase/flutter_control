part of flutter_control;

mixin OverlayControl on CoreWidget {
  OverlayEntry? showOverlay({
    required CoreContext context,
    required dynamic key,
    required Widget Function(Rect parent) builder,
    GlobalKey? parentKey,
    bool barrierDismissible = true,
  }) {
    final overlay = Overlay.of(context);

    if (context.args.containsKey(ObjectTag.of(key))) {
      return getOverlay(context, key);
    }

    if (key is GlobalKey && parentKey == null) {
      parentKey = key;
    }

    final box = (parentKey?.currentState?.context.findRenderObject() ??
        context.findRenderObject()) as RenderBox;
    final location = box.localToGlobal(Offset.zero);
    final size = box.size;

    final child = builder(
        Rect.fromLTWH(location.dx, location.dy, size.width, size.height));

    final entry = OverlayEntry(
      builder: (_) => barrierDismissible
          ? Stack(
              children: [
                GestureDetector(
                  onTap: () => hideOverlay(context, key),
                ),
                child,
              ],
            )
          : child,
    );

    context.args.add(key: ObjectTag.of(key), value: entry);

    overlay.insert(entry);

    return entry;
  }

  OverlayEntry? getOverlay(CoreContext context, dynamic key) =>
      context.args.get<OverlayEntry>(key: ObjectTag.of(key));

  bool hideOverlay(CoreContext context, dynamic key) {
    final overlay = getOverlay(context, key);

    if (overlay != null) {
      overlay.remove();
      context.args.remove(key: ObjectTag.of(key));

      return true;
    }

    return false;
  }

  bool clearOverlays(CoreContext context) {
    final items = context.args.getAll<OverlayEntry>();

    if (items.isNotEmpty) {
      items.forEach((element) {
        element.remove();
      });

      context.args.removeAll<OverlayEntry>();

      return true;
    }

    return false;
  }
}
