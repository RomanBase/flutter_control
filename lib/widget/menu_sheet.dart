import 'package:flutter_control/core.dart';

typedef MenuItemBuilder<Widget>(BuildContext context, MenuSheetItem item);

/// Menu item entity
class MenuSheetItem {
  /// Text key of menu item.
  final String key;

  /// Icon name, or path to asset.
  /// Can be null.
  final String icon;

  /// Menu item title.
  /// Can be null.
  final String title;

  /// Callback when menu item is selected.
  final Getter onItemSelected;

  /// Default constructor.
  MenuSheetItem({this.key, this.icon, this.title, this.onItemSelected});
}

/// BaseController of menu items.
class MenuSheetController extends BaseController {
  final List<MenuSheetItem> items;

  /// Default constructor.
  MenuSheetController(this.items);

  @override
  Widget initWidget() => MenuSheet(controller: this);
}

/// Custom Widget menu to build mainly Dialog sheets.
/// This class provides separate builder methods for different parts of menu to build more complex menus.
class MenuSheet<T extends MenuSheetController> extends ControlWidget<T> {
  /// Widget builder for menu item.
  final MenuItemBuilder itemBuilder;

  /// Default constructor.
  MenuSheet({@required T controller, Key key, this.itemBuilder}) : super(controller: controller, key: key);

  @override
  State<StatefulWidget> createState() => _MenuSheetState();

  /// Builds enclosure container of menu.
  Widget buildContainer(BuildContext context, Widget header, Widget footer, List<Widget> items) {
    final list = List<Widget>();

    if (header != null) {
      list.add(header);
    }

    list.addAll(items);

    if (footer != null) {
      list.add(footer);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }

  /// Builds just header part of menu.
  Widget buildHeader(BuildContext context, T controller) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      height: 8.0,
      width: 72.0,
      decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.all(
            Radius.circular(4.0),
          )),
    );
  }

  /// Builds just footer part of menu.
  Widget buildFooter(BuildContext context, T controller) {
    return SizedBox(height: 16.0);
  }

  /// Builds one item of menu.
  /// But item builder passed in constructor has more priority then this method.
  Widget buildItem(BuildContext context, MenuSheetItem item) {
    final list = List<Widget>();

    if (item.icon != null) {
      list.add(Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          item.icon,
          width: 24.0,
          height: 24.0,
        ),
      ));
    }

    if (item.title != null) {
      list.add(Text(item.title));
    }

    return SizedBox(
      height: 56.0,
      child: FlatButton(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: list,
        ),
        onPressed: item.onItemSelected,
      ),
    );
  }
}

/// State for MenuSheet.
/// Build phase is exposed back to MenuSheet Widget for easier integration and custom menu part overrides.
class _MenuSheetState<T extends MenuSheetController> extends BaseState<T, MenuSheet> {
  @override
  Widget buildWidget(BuildContext context, T controller) {
    final items = List<Widget>();
    final header = widget.buildHeader(context, controller);
    final footer = widget.buildFooter(context, controller);

    if (widget.itemBuilder == null) {
      for (final item in controller.items) {
        items.add(widget.buildItem(context, item));
      }
    } else {
      for (final item in controller.items) {
        items.add(widget.itemBuilder(context, item));
      }
    }

    return widget.buildContainer(context, header, footer, items);
  }
}
