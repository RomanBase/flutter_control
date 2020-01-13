import 'package:flutter_control/core.dart';
import '../control/spend_item_control.dart';

class SpendItemDialog extends SingleControlWidget<SpendItemControl> with ThemeProvider, RouteNavigator {
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InputField(
                control: control.title,
                textInputAction: TextInputAction.next,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: InputField(
                      control: control.value,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: theme.padding),
                    child: FieldBuilder<bool>(
                      control: control.sub,
                      builder: (context, value) => Checkbox(
                        value: value,
                        onChanged: control.sub.setValue,
                      ),
                    ),
                  ),
                ],
              ),
              InputField(
                control: control.note,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(
                height: theme.paddingExtended,
              ),
              FlatButton(
                onPressed: control.submit,
                child: Text('submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
