import 'package:flutter_control/core.dart';
import 'package:spends/control/spend/spend_item_control.dart';
import 'package:spends/theme.dart';
import 'package:spends/widget/button.dart';
import 'package:spends/widget/input_decoration.dart';

class SpendGroupEditDialog extends SingleControlWidget<SpendItemControl>
    with ThemeProvider<SpendTheme>, RouteControl {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: close,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () {},
          child: SingleChildScrollView(
            child: Container(
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
                  FadeButton(
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
        ),
      ),
    );
  }
}
