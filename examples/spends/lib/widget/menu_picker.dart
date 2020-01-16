import 'package:flutter_control/core.dart';

class MenuPickerItem {
  final dynamic key;
  final String title;
  final String icon;

  const MenuPickerItem({
    @required this.key,
    this.title,
    this.icon,
  });
}

class MenuPicker extends StatelessWidget {
  final ActionControl control;
  final List<MenuPickerItem> items;
  final bool expand;

  MenuPicker({
    Key key,
    @required this.control,
    this.items: const [],
    this.expand: true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionBuilder(
        control: control,
        builder: (context, value) {
          return Row(
            children: <Widget>[
              for (MenuPickerItem item in items) _buildItem(context, item, value),
            ],
          );
        });
  }

  Widget _buildItem(BuildContext context, MenuPickerItem item, dynamic value) {
    final button = FlatButton(
      onPressed: () => control.value = item.key,
      padding: EdgeInsets.all(0.0),
      color: item.key == value ? Theme.of(context).primaryColorLight : Colors.transparent,
      child: Text(item.title ?? ''),
    );

    if (expand) {
      return Expanded(
        child: button,
      );
    }

    return button;
  }
}
