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

class MenuSheet extends ControlWidget<MenuSheetController> {
  final ItemBuilder itemBuilder;
  final WidgetBuilder headerBuilder;
  final WidgetBuilder footerBuilder;

  MenuSheet({@required MenuSheetController controller, this.itemBuilder, this.headerBuilder, this.footerBuilder}) : super(controller: controller);

  @override
  State<StatefulWidget> createState() => _MenuSheetState();

  Widget buildContainer(BuildContext context, List<Widget> widgets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }
}

class _MenuSheetState extends BaseState<MenuSheetController, MenuSheet> {
  @override
  Widget buildWidget(BuildContext context, MenuSheetController controller) {
    final list = List<Widget>();
    final header = widget.headerBuilder == null ? buildHeader() : widget.headerBuilder(context);
    final footer = widget.footerBuilder == null ? buildFooter() : widget.headerBuilder(context);

    if (header != null) {
      list.add(header);
    }

    if (widget.itemBuilder == null) {
      for (final item in controller.items) {
        list.add(buildItem(item));
      }
    } else {
      for (final item in controller.items) {
        list.add(widget.itemBuilder(context, item));
      }
    }

    if (footer != null) {
      list.add(footer);
    }

    return widget.buildContainer(context, list);
  }

  Widget buildHeader() {
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

  Widget buildFooter() {
    return SizedBox(height: 16.0);
  }

  Widget buildItem(MenuSheetItem item) {
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
