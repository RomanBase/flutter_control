import 'package:flutter_control/core.dart';

int _itemIndex = 0;

class ItemModel extends BaseModel {
  String title;

  ItemModel() {
    title = UnitId.charId(_itemIndex++);
  }
}

class ItemsControl extends BaseControl {
  final loading = LoadingControl();
  final list = ListControl<BaseModel>();

  @override
  void onInit(Map args) {
    super.onInit(args);

    loadMore();
  }

  void loadMore() async {
    if (!loading.isDone) {
      return;
    }

    loading.progress();
    await Future.delayed(Duration(seconds: 2));
    loading.done();

    list.addAll(Parse.toList(List(10), converter: (x) => ItemModel()));
  }
}
