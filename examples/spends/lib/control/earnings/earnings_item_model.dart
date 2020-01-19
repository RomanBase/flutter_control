import 'package:flutter_control/core.dart';
import 'package:spends/entity/earnings_item.dart';

class EarningsItemModel extends BaseModel with StateControl {
  final loading = LoadingControl();

  EarningsItem _item;

  EarningsItem get item => _item;

  set item(EarningsItem value) {
    _item = value;
    notifyState();
  }

  EarningsItemModel(EarningsItem item) {
    _item = item;
  }

  @override
  void dispose() {
    super.dispose();
    loading.dispose();
  }
}
