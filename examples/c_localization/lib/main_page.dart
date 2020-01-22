import 'package:flutter_control/core.dart';

import 'settings_page.dart';

class MainPage extends ControlWidget with RouteNavigator {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localize('main_title')),
        actions: <Widget>[
          IconButton(
            onPressed: () => routeOf<SettingsPage>().openRoute(),
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              localize('title'),
              style: Theme.of(context).textTheme.display2,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: <Widget>[
                  RowItem(
                    index: 1,
                  ),
                  RowItem(
                    index: 2,
                  ),
                  RowItem(
                    index: 5,
                  ),
                  RowItem(
                    index: 20,
                  ),
                  RowItem(
                    index: -1,
                  ),
                  RowItem(
                    index: 0,
                  ),
                ],
              ),
            ),
            Text(
              extractLocalization({
                'en': 'Hi, current localization is se to English.',
                'es': 'Hola, la localización actual es para español.',
              }),
              style: Theme.of(context).textTheme.title,
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  RaisedButton(
                    onPressed: () => Control.localization().changeLocale('en'),
                    child: Text(localize('button_en')),
                  ),
                  RaisedButton(
                    onPressed: () => Control.localization().changeLocale('es'),
                    child: Text(localize('button_es')),
                  ),
                ],
              ),
            ),
            Text(
              localize('test').toUpperCase() + ' - without delegate',
            ),
          ],
        ),
      ),
    );
  }
}

class RowItem extends StatelessWidget with LocalizationProvider {
  final int index;

  RowItem({Key key, this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(index.toString()),
        Text(localizePlural('index', index, {'{n}': index.toString()})),
      ],
    );
  }
}
