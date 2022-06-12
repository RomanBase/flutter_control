import 'package:flutter_control/control.dart';
import 'package:spends/data/repo_provider.dart';
import 'package:spends/entity/spend_item.dart';

class SpendItemModel extends BaseModel with ObservableComponent, RepoProvider {
  final loading = LoadingControl();

  SpendItem _item;

  SpendItem get item => _item;

  set item(SpendItem value) {
    _item = value;
    notify();
  }

  SpendItemModel(SpendItem item) {
    _item = item;
  }

  Future<void> addItemToGroup(SpendItem item) async {
    loading.progress();

    if (_item.items == null) {
      _item = _item.copyWith(items: []);
    }

    _item.items.add(item);

    await spendRepo.update(_item);

    loading.done();
  }

  Future<void> updateGroupItem(SpendItemModel model, SpendItem item) async {
    loading.progress();

    final index = _item.items.indexOf(model.item);

    if (index > -1) {
      _item.items.removeAt(index);
      _item.items.insert(index, item);
    } else {
      printDebug("Item to update not found !");
    }

    await spendRepo.update(_item);

    loading.done();
  }

  Future<void> removeItemFromGroup(SpendItem item) async {
    loading.progress();

    _item.items.remove(item);
    await spendRepo.update(_item);

    loading.done();
  }

  @override
  void dispose() {
    super.dispose();

    loading.dispose();
  }
}
