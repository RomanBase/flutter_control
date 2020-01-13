import 'package:flutter_control/core.dart';
import 'package:spends/control/init_control.dart';
import 'package:spends/widget/input_decoration.dart';

class InitPage extends SingleControlWidget<InitControl> with ThemeProvider {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(theme.paddingExtended),
        color: Colors.green,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 256.0,
            ),
            InputField(
              control: control.username,
              decoration: RoundInputDecoration(),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(
              height: theme.paddingMid,
            ),
            InputField(
              control: control.password,
              obscureText: true,
              decoration: RoundInputDecoration(),
              textInputAction: TextInputAction.done,
            ),
            SizedBox(
              height: theme.paddingExtended,
            ),
            LoadingBuilder(
              control: control.loading,
              progress: (context) => CircularProgressIndicator(),
              done: (context) => FlatButton(
                onPressed: control.submit,
                child: Text(
                  localize('submit'),
                  style: font.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
