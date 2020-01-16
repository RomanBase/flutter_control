import 'package:flutter_control/core.dart';
import 'package:spends/entity/spend_item.dart';
import 'package:spends/main.dart';
import 'package:spends/widget/input_decoration.dart';
import 'package:spends/widget/menu_picker.dart';

import '../control/spend_item_control.dart';

class SpendItemDialog extends SingleControlWidget<SpendItemControl> with ThemeProvider<SpendTheme>, RouteNavigator {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: close,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          margin: EdgeInsets.all(theme.padding),
          padding: EdgeInsets.all(theme.padding),
          decoration: BoxDecoration(
            color: theme.data.canvasColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InputField(
                control: control.title,
                textInputAction: TextInputAction.next,
                decoration: RoundInputDecoration(color: theme.lightGray),
                label: localize('title'),
              ),
              SizedBox(
                height: theme.paddingMid,
              ),
              MenuPicker(
                control: control.type,
                items: [
                  MenuPickerItem(
                    key: SpendType.normal,
                    title: 'normal',
                  ),
                  MenuPickerItem(
                    key: SpendType.sub,
                    title: 'sub',
                  ),
                  MenuPickerItem(
                    key: SpendType.group,
                    title: 'group',
                  ),
                ],
              ),
              ActionBuilder(
                control: control.type,
                builder: (context, value) {
                  if (value == SpendType.group) {
                    return SizedBox(
                      height: theme.paddingMid,
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: theme.paddingMid),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: InputField(
                            control: control.value,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: RoundInputDecoration(color: theme.lightGray),
                            label: localize('value'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: MenuPicker(
                  control: control.group,
                  expand: false,
                  items: [
                    MenuPickerItem(
                      key: 'none',
                      title: 'none',
                    ),
                    ...control.groups
                        .map(
                          (item) => MenuPickerItem(
                            key: item.id,
                            title: item.title,
                          ),
                        )
                        .toList(growable: false),
                  ],
                ),
              ),
              SizedBox(
                height: theme.paddingMid,
              ),
              InputField(
                control: control.note,
                textInputAction: TextInputAction.done,
                minLines: 2,
                maxLines: 2,
                decoration: RoundInputDecoration(color: theme.lightGray),
                label: localize('note'),
              ),
              SizedBox(
                height: theme.paddingExtended,
              ),
              FlatButton(
                onPressed: control.submit,
                child: Text(
                  localize('submit'),
                  style: font.button,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
