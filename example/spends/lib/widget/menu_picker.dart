import 'package:flutter_control/core.dart';
import 'package:spends/theme.dart';
import 'package:spends/widget/button.dart';

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

class MenuPicker extends StatelessWidget with ThemeProvider<SpendTheme> {
  final ActionControl control;
  final List<MenuPickerItem> items;
  final bool wrap;

  MenuPicker({
    Key key,
    @required this.control,
    this.items: const [],
    this.wrap: false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionBuilder(
        control: control,
        builder: (context, value) {
          final buttons = items.map((item) => _buildItem(context, item, value == item.key)).toList(growable: false);

          return wrap
              ? Wrap(
                  spacing: theme.paddingHalf,
                  runSpacing: theme.paddingHalf,
                  children: buttons,
                )
              : Row(
                  children: buttons,
                );
        });
  }

  Widget _buildItem(BuildContext context, MenuPickerItem item, bool selected) {
    final button = RoundedButton(
      onPressed: () => control.value = item.key,
      padding: EdgeInsets.symmetric(horizontal: theme.paddingMid),
      height: 32.0,
      color: selected ? theme.primaryColorLight : Colors.transparent,
      outline: selected ? theme.primaryColorLight : theme.gray.withOpacity(0.5),
      title: item.title ?? '-',
      style: font.button.copyWith(fontWeight: FontWeight.w300),
    );

    if (wrap) {
      return button;
    }

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.paddingQuad),
        child: button,
      ),
    );
  }
}
