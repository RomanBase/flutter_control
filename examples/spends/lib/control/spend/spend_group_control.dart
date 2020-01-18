import 'package:flutter_control/core.dart';
import 'package:spends/control/spend/spend_control.dart';
import 'package:spends/control/spend/spend_item_model.dart';
import 'package:spends/entity/spend_item.dart';

class SpendGroupControl extends BaseControl {
  final yearSpend = StringControl();
  final monthAvgSpend = StringControl();
  final monthSubSpend = StringControl('todo');

  final list = ListControl<SpendItemModel>();

  SpendControl get control => Control.get<SpendControl>();
  SpendItemModel group;

  @override
  void onInit(Map args) {
    super.onInit(args);

    group = args.getArg<SpendItemModel>();

    if (group == null) {
      throw ('Initialized Group Control without Model !');
    }

    _updateData();

    group.item.items.sort(SpendItem.byTitle);
    list.setValue(group.item.items.map((item) => SpendItemModel(item)));
  }

  void _updateData() {
    yearSpend.value = group.item.yearSpend.toInt().toString();
    monthAvgSpend.value = group.item.monthSpend.toInt().toString();
    monthSubSpend.value = group.item.subSpend.toInt().toString();
  }

  void addItem(SpendItem item) async {
    final model = SpendItemModel(item);
    model.loading.progress();
    list.add(model);

    await group.addItemToGroup(item);

    _updateData();
    model.loading.done();
  }

  void updateItem(SpendItemModel model, SpendItem item) async {
    model.loading.progress();

    await group.updateGroupItem(model, item);

    _updateData();
    model.loading.done();
  }

  void removeItem(SpendItemModel model) async {
    model.loading.progress();

    await group.removeItemFromGroup(model.item);

    list.remove(model);
    _updateData();
  }

  @override
  void dispose() {
    super.dispose();

    yearSpend.dispose();
    monthAvgSpend.dispose();
    monthSubSpend.dispose();
  }
}
