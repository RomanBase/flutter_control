import 'package:flutter_control/core.dart';

mixin OverlayControl on CoreWidget {
  OverlayEntry? showOverlay({
    required dynamic key,
    required Widget Function(Rect parent) builder,
    GlobalKey? parentKey,
    bool barrierDismissible: true,
  }) {
    assert(isInitialized);

    final overlay = Overlay.of(context!);

    if (overlay == null) {
      return null;
    }

    if (getArgStore().containsKey(ObjectTag.of(key))) {
      return getOverlay(key);
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
    final items = getArgStore().getAll<OverlayEntry>();

    if (items.isNotEmpty) {
      items.forEach((element) {
        element.remove();
      });

      getArgStore().removeAll<OverlayEntry>();

      return true;
    }

    return false;
  }
}
