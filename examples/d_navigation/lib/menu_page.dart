import 'package:flutter_control/core.dart';

import './page/main_page.dart';
import './page/template_page.dart';

const _menu = ['main', 'inside', 'dialog', 'hello'];

final _menu2 = <String, dynamic>{
  'main': (_) => MainPage(),
  'inside': (_) => NavigatorStack.single(builder: (_) => MainPage()),
  'dialog': (_) => null,
  'hello': (_) => null,
};

class TabControl extends ControlModel {
  TabController tab;

  @override
  void onTickerInitialized(TickerProvider ticker) {
    tab = TabController(
      length: _menu.length,
      vsync: ticker,
    );
  }

  Future<bool> navigateBack() async {
    if (tab.index > 0) {
      tab.index = 0;
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    super.dispose();

    tab.dispose();
  }
}

class MenuPage extends SingleControlWidget<TabControl> with TickerControl, RouteNavigator {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: control.navigateBack,
      child: Column(
        children: <Widget>[
          Expanded(
            child: TabBarView(
              controller: control.tab,
              children: [
                _menu2['main'](context),
                _menu2['inside'](context),
                TemplatePage(
                  title: 'dialogs',
                  color: Colors.green,
                  child: Column(
                    children: <Widget>[
                      RaisedButton(
                        onPressed: () {},
                        child: Text('popup'),
                      ),
                      RaisedButton(
                        onPressed: () {},
                        child: Text('popup inside'),
                      ),
                      RaisedButton(
                        onPressed: () {},
                        child: Text('dialog'),
                      ),
                      RaisedButton(
                        onPressed: () {},
                        child: Text('sheet'),
                      ),
                    ],
                  ),
                ),
                TemplatePage(
                  title: 'hello',
                ),
              ],
            ),
          ),
          NotifierBuilder<TabController>(
            control: control.tab,
            builder: (context, tab) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  for (int i = 0; i < _menu.length; i++)
                    RaisedButton(
                      onPressed: () => tab.index = i,
                      color: tab.index == i ? Colors.amberAccent : Colors.grey,
                      child: Text(_menu[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
