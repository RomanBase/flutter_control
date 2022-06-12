import 'package:flutter_control/control.dart';
import 'package:spends/entity/earnings_item.dart';

class EarningsItemModel extends BaseModel with NotifierComponent {
  final loading = LoadingControl();

  EarningsItem _item;

  EarningsItem get item => _item;

  set item(EarningsItem value) {
    _item = value;
    notify();
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
