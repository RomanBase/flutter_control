import 'package:flutter_control/core.dart';

typedef ItemBuilder<Widget>(BuildContext context, MenuSheetItem item);

class MenuSheetItem {
  final String key;
  final String icon;
  final String title;
  final Action onItemSelected;

  MenuSheetItem({this.key, this.icon, this.title, this.onItemSelected});
}

class MenuSheetController extends BaseController {
  final List<MenuSheetItem> items;

  MenuSheetController(this.items);

  @override
  Widget initWidget() => MenuSheet(controller: this);
}

class MenuSheet<T extends MenuSheetController> extends ControlWidget<T> {
  final ItemBuilder itemBuilder;

  MenuSheet({@required T controller, this.itemBuilder}) : super(controller: controller);

  @override
  State<StatefulWidget> createState() => _MenuSheetState();

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

  Widget buildFooter(BuildContext context, T controller) {
    return SizedBox(height: 16.0);
  }

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
