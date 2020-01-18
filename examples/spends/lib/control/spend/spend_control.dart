import 'package:flutter_control/core.dart';
import 'package:spends/data/spend_repo.dart';
import 'package:spends/entity/spend_item.dart';
import 'package:spends/fire/fire_control.dart';

import 'spend_item_model.dart';

class SpendControl extends BaseControl {
  final loading = LoadingControl();

  final list = ListControl<SpendItemModel>();

  final yearSpend = StringControl();
  final monthAvgSpend = StringControl();
  final monthSubSpend = StringControl();

  //TODO: group in group - func
  List<SpendItem> get groups => list.where((model) => model.item.isGroup).map((model) => model.item).toList(growable: false);

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
      data.sort(SpendItem.byTitle);
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

      if (item.isSub) {
        monthSub += item.monthSpend;
      }
    });

    yearSpend.value = year.toInt().toString();
    monthAvgSpend.value = monthAvg.toInt().toString();
    monthSubSpend.value = monthSub.toInt().toString();
  }

  //TODO: group in group
  SpendItemModel findGroup(String id) => list.firstWhere((model) => model.item.id == id && model.item.isGroup);

  Future<void> addItem(SpendItem item) async {
    if (item.groupId != null) {
      final group = findGroup(item.groupId);

      if (group != null) {
        return group.addItemToGroup(item);
      }
    }

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

    bool movedToGroup = false;
    if (model.item.groupId == null && item.groupId != null) {
      final group = findGroup(item.groupId);

      if (group != null) {
        group.loading.progress();
        group.item.items.add(item);

        final remove = spendRepo.remove(model.item).then((_) {
          list.remove(model);
        }); //TODO: catch error...

        final update = spendRepo.update(group.item, group.item).then((data) {
          group.item = data;
        });

        await Future.wait([remove, update]);

        movedToGroup = true;
        group.loading.done();
      }
    }

    if (!movedToGroup) {
      await spendRepo.update(model.item, item).then((data) {
        model.item = data;
      });
    }

    _recalculateData(list.value);

    model.loading.done();
  }
}
