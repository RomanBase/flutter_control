import 'package:flutter_control/control.dart';
import 'package:spends/data/repo_provider.dart';
import 'package:spends/entity/earnings_item.dart';
import 'package:spends/fire/fire_control.dart';

import 'earnings_item_model.dart';

class EarningsControl extends BaseControl with FireProvider, RepoProvider {
  final loading = LoadingControl();
  final list = ListControl<EarningsItemModel>();

  final yearEarnings = StringControl();

  final extraEarnings = StringControl();

  final monthSubEarnings = StringControl();

  @override
  void onInit(Map args) {
    super.onInit(args);

    list.subscribe(_recalculateData);

    fire.userSub.subscribe((user) {
      if (user != null) {
        _fetchData();
      }
    });
  }

  void _fetchData() async {
    loading.progress();

    await earningsRepo.getEarnings().then((data) {
      data.sort(EarningsItem.byTitle);
      list.setValue(data.map((item) => EarningsItemModel(item)));
    });

    loading.done();
  }

  void _recalculateData(List<EarningsItemModel> data) {
    double year = 0.0;
    double extra = 0.0;
    double sub = 0.0;

    data.forEach((spend) {
      final item = spend.item;

      year += item.yearEarnings;
      extra += item.extraEarnings;
      sub += item.subEarnings;
    });

    yearEarnings.value = year.toInt().toString();
    extraEarnings.value = extra.toInt().toString();
    monthSubEarnings.value = sub.toInt().toString();
  }

  void addItem(EarningsItem item) async {
    final model = EarningsItemModel(item);
    model.loading.progress();
    list.add(model);

    await earningsRepo.add(item).then((data) {
      model.item = data;
    });

    model.loading.done();
  }

  void updateItem(EarningsItemModel model, EarningsItem item) async {
    model.loading.progress();

    await earningsRepo.update(model.item, item).then((data) {
      model.item = data;
    });

    model.loading.done();
  }

  void removeItem(EarningsItemModel model) async {
    model.loading.progress();

    await earningsRepo.remove(model.item).then((_) {
      list.remove(model);
    });

    model.loading.done();
  }

  @override
  void softDispose() {
    super.softDispose();

    list.clear(disposeItems: true);
    yearEarnings.value = null;
    extraEarnings.value = null;
    monthSubEarnings.value = null;
  }

  @override
  void dispose() {
    super.dispose();

    list.clear(disposeItems: true);
    list.dispose();
    yearEarnings.dispose();
    extraEarnings.dispose();
    monthSubEarnings.dispose();
  }
}
