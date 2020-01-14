import 'package:flutter_control/core.dart';
import 'package:spends/data/spend_repo.dart';
import 'package:spends/entity/spend_item.dart';
import 'package:spends/fire/fire_control.dart';

class SpendItemModel extends BaseModel with StateControl {
  final loading = LoadingControl();

  SpendItem _item;

  SpendItem get item => _item;

  set item(SpendItem value) {
    _item = value;
    notifyState();
  }

  SpendItemModel(SpendItem item) {
    this.item = item;
  }

  @override
  void dispose() {
    super.dispose();

    loading.dispose();
  }
}

class SpendControl extends BaseControl {
  final loading = LoadingControl();

  final list = ListControl<SpendItemModel>();

  final yearSpend = StringControl();
  final monthAvgSpend = StringControl();
  final monthSubSpend = StringControl();

  SpendRepo get spendRepo => Control.get<SpendRepo>();

  SpendControl() {
    autoDispose([
      loading,
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

    Control.get<FireControl>().userSub.subscribe((user) {
      if (user != null) {
        _fetchData();
      }
    });
  }

  void _fetchData() async {
    loading.progress();

    await spendRepo.getSpends().then((data) {
      list.setValue(data.map((item) => SpendItemModel(item)));
    });

    loading.done();
  }

  void _recalculateData(List<SpendItemModel> data) {
    double year = 0.0;
    double monthAvg = 0.0;
    double monthSub = 0.0;
    double yearSavings = 0.0;
    double monthSavings = 0.0;

    data.forEach((spend) {
      final item = spend.item;

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

  Future<void> addItem(SpendItem item) async {
    final model = SpendItemModel(item);
    list.add(model);

    model.loading.progress();

    await spendRepo.add(model.item).then((data) {
      model.item = data;
    });

    model.loading.done();
  }

  void removeItem(SpendItemModel model) async {
    model.loading.progress();

    await spendRepo.remove(model.item).then((_) {
      list.remove(model);
    });

    model.loading.done();
  }

  void updateItem(SpendItemModel model, SpendItem item) async {
    model.loading.progress();

    await spendRepo.update(model.item, item).then((data) {
      model.item = data;
    });

    model.loading.done();
  }
}
