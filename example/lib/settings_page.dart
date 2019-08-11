import 'package:flutter_control/core.dart';
import 'package:flutter_control_example/settings_controller.dart';

class SettingsPage extends ControlWidget {
  static PageRouteProvider route() => PageRouteProvider.of(
        identifier: '/settings',
        builder: (context) => SettingsPage(),
      );

  SettingsController get controller => controllers[0];

  @override
  List<BaseController> initControllers() {
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
            StableWidget(
              localize: false,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  localize('localization_info'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
