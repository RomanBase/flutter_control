import 'package:spends/entity/spend_item.dart';

abstract class SpendRepo {
  Future<List<SpendItem>> getSpends();

  Future<SpendItem> add(SpendItem item);

  Future<SpendItem> update(SpendItem origin, SpendItem item);

  Future<void> remove(SpendItem item);
}
