import 'package:flutter_control/core.dart';

class SpendItem {
  final String title;
  final String note;
  final num value;
  final num possibleSavings;
  final bool subscription;

  num get yearSpend => subscription ? value * 12.0 : value;

  num get monthSpend => subscription ? value : value / 12.0;

  num get yearSavings => subscription ? possibleSavings * 12.0 : possibleSavings;

  num get monthSavings => subscription ? possibleSavings : possibleSavings / 12.0;

  SpendItem({
    @required this.title,
    this.note,
    this.value: 0.0,
    this.possibleSavings: 0.0,
    this.subscription: false,
  });
}

class SpendControl extends BaseControl {
  final list = ListControl<SpendItem>();

  final yearSpend = StringControl();
  final monthAvgSpend = StringControl();
  final monthSubSpend = StringControl();

  SpendControl() {
    autoDispose([
      list,
      yearSpend,
      monthAvgSpend,
      monthSubSpend,
    ]);
  }

  @override
  void onInit(Map args) {
    super.onInit(args);

    list.subscribe(_recalculateData);
  }

  void _recalculateData(List<SpendItem> data) {
    double year = 0.0;
    double monthAvg = 0.0;
    double monthSub = 0.0;
    double yearSavings = 0.0;
    double monthSavings = 0.0;

    data.forEach((item) {
      year += item.yearSpend;
      monthAvg += item.monthSpend;

      if (item.subscription) {
        monthSub += item.monthSpend;
        monthSavings += item.monthSavings;
      } else {
        yearSavings += item.yearSavings;
      }
    });

    yearSpend.value = year.toInt().toString();
    monthAvgSpend.value = monthAvg.toInt().toString();
    monthSubSpend.value = monthSub.toInt().toString();
  }

  void addItem(SpendItem item) => list.add(item);

  void removeItem(SpendItem item) => list.remove(item);

  void updateItem(SpendItem origin, SpendItem item) => list.replace(item, (listItem) => listItem == origin);
}
