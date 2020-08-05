import 'package:flutter_control/core.dart';
import 'package:spends/control/earnings/earnings_control.dart';
import 'package:spends/control/earnings/earnings_item_model.dart';
import 'package:spends/theme.dart';
import 'package:spends/widget/tab_row.dart';

import 'earnings_item_dialog.dart';
import 'earnings_list_item.dart';

class EarningsPage extends SingleControlWidget<EarningsControl>
    with ThemeProvider<SpendTheme>, RouteControl {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            width: device.width,
            padding: EdgeInsets.only(
                top: device.topBorderSize + theme.padding,
                bottom: theme.padding,
                left: theme.padding,
                right: theme.padding),
            color: theme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                TabRow(
                  title: 'Total year earnings',
                  control: control.yearEarnings,
                ),
                TabRow(
                  title: 'Extra year earnings',
                  control: control.extraEarnings,
                  style: font.bodyText2,
                ),
                SizedBox(
                  height: theme.paddingQuarter,
                ),
                TabRow(
                  title: 'Sub month earnings',
                  control: control.monthSubEarnings,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListBuilder<EarningsItemModel>(
              control: control.list,
              builder: (context, data) => ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                    top: theme.paddingQuad, bottom: theme.paddingExtended),
                itemCount: data.length,
                itemBuilder: (context, index) => EarningsListItem(
                  model: data[index],
                  onPressed: (item) {
                    routeOf<EarningsItemDialog>().openDialog(args: item);
                  },
                  onRemove: (item) => control.removeItem(item),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
