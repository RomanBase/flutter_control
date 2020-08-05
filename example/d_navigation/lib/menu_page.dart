import 'package:d_navigation/page/dialog_page.dart';
import 'package:flutter_control/core.dart';

import './page/main_page.dart';
import './page/template_page.dart';

class TabItem {
  final String key;
  final WidgetBuilder builder;

  const TabItem({this.key, this.builder});
}

final _insideControl = NavigatorControl();
final _dialogControl = NavigatorControl();

final _menu = [
  TabItem(
    key: 'main',
    builder: (_) => MainPage(),
  ),
  TabItem(
    key: 'inside',
    builder: (_) => NavigatorStack.single(
        builder: (_) => MainPage(), control: _insideControl),
  ),
  TabItem(
    key: 'dialog',
    builder: (_) => NavigatorStack.single(
        builder: (_) => DialogPage(), control: _dialogControl),
  ),
  TabItem(
    key: 'hello',
    builder: (_) => TemplatePage(title: 'hello'),
  ),
];

class TabControl extends ControlModel
    with RouteControlProvider, TickerComponent {
  TabController tab;

  @override
  void onTickerInitialized(TickerProvider ticker) {
    tab = TabController(
      length: _menu.length,
      vsync: ticker,
    );
  }

  Future<bool> popScope() async {
    if (_insideControl.navigateBack()) {
      return false;
    }

    if (_dialogControl.navigateBack()) {
      return false;
    }

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

class MenuPage extends SingleControlWidget<TabControl>
    with TickerControl, RouteControl {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: control.popScope,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: TabBarView(
                controller: control.tab,
                children: [
                  for (final item in _menu) item.builder(context),
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
                        color:
                            tab.index == i ? Colors.amberAccent : Colors.grey,
                        child: Text(_menu[i].key),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
