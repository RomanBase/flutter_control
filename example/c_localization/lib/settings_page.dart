import 'package:flutter_control/core.dart';

class SettingsPage extends ControlWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localize('settings_title')),
      ),
      body: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              extractLocalization({
                'en': 'Hi, current localization is se to English.',
                'es': 'Hola, la localización actual es para español.',
              }),
              style: Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  RaisedButton(
                    onPressed: () => Control.localization.changeLocale('en'),
                    child: Text(localize('button_en')),
                  ),
                  RaisedButton(
                    onPressed: () => Control.localization.changeLocale('es'),
                    child: Text(localize('button_es')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
