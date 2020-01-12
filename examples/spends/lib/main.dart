import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';
import 'package:spends/control/spend_control.dart';
import 'package:spends/page/init_page.dart';
import 'package:spends/page/spend_list_page.dart';

import 'control/init_control.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      entries: {
        SpendControl: SpendControl(),
      },
      loader: (_) => InitLoader(
        control: InitControl(),
        builder: (_) => InitPage(),
      ),
      root: (_, args) => SpendListPage(),
      app: (context, key, home) => MaterialApp(
        title: 'Spend List',
        key: key,
        home: home,
      ),
    );
  }
}
