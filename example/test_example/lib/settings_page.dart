import 'package:flutter_control/core.dart';

import 'main.dart';
import 'settings_controller.dart';

class SettingsPage extends ControlWidget with ThemeProvider<MyTheme> {
  SettingsController get controller => controls[0];

  @override
  List<BaseControl> initControls() {
    return [SettingsController()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localize('settings')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                localize('lorem_ipsum'),
                textAlign: TextAlign.center,
              ),
            ),
            RaisedButton(
              onPressed: controller.changeLocaleToEN,
              child: Text('change locale to EN'),
            ),
            RaisedButton(
              onPressed: controller.changeLocaleToCS,
              child: Text('change locale to CS'),
            ),
            RaisedButton(
              onPressed: controller.toggleTheme,
              child: Text(
                'toggle Theme',
              ),
            ),
            RaisedButton(
              onPressed: controller.unloadApp,
              child: Text('unload'),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                localize('localization_info'),
                textAlign: TextAlign.center,
                style: font.bodyText1.copyWith(color: theme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
