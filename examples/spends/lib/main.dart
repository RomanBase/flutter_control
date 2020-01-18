import 'package:flutter/material.dart';
import 'package:flutter_control/core.dart';
import 'package:spends/control/spend/spend_group_control.dart';
import 'package:spends/data/spend_repo.dart';
import 'package:spends/fire/fire_spend.dart';
import 'package:spends/page/init_page.dart';
import 'package:spends/page/menu_page.dart';
import 'package:spends/page/spend/spend_group_page.dart';
import 'package:spends/theme.dart';

import 'control/init_control.dart';
import 'control/spend/spend_control.dart';
import 'control/spend/spend_item_control.dart';
import 'fire/fire_control.dart';
import 'page/account/account_page.dart';
import 'page/earnings/earnings_page.dart';
import 'page/spend/spend_item_dialog.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      debug: true,
      locales: {
        'en': 'assets/localization/en.json',
      },
      entries: {
        NavigatorStackControl: NavigatorStackControl(),
        FireControl: FireControl(),
        SpendControl: SpendControl(),
      },
      initializers: {
        InitLoaderControl: (_) => InitControl(),
        SpendRepo: (_) => FireSpendRepo(),
        SpendItemControl: (_) => SpendItemControl(),
        SpendGroupControl: (_) => SpendGroupControl(),
      },
      routes: [
        ControlRoute.build<SpendItemDialog>(builder: (_) => SpendItemDialog()),
        ControlRoute.build<SpendGroupPage>(builder: (_) => SpendGroupPage()),
        ControlRoute.build<AccountPage>(builder: (_) => AccountPage()),
        ControlRoute.build<EarningsPage>(builder: (_) => EarningsPage()),
      ],
      theme: (context) => SpendTheme(context),
      loader: (_) => InitLoader(
        builder: (_) => InitPage(),
      ),
      root: (_, args) => MenuPage(),
      app: (context, key, home) => MaterialApp(
        debugShowCheckedModeBanner: false,
        key: key,
        home: home,
        title: 'Spend List',
        theme: SpendTheme().darkTheme,
      ),
    );
  }
}
