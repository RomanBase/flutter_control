import 'package:spends/entity/earnings_item.dart';

abstract class EarningsRepo {
  Future<List<EarningsItem>> getEarnings();

  Future<EarningsItem> add(EarningsItem item);

  Future<EarningsItem> update(EarningsItem origin, [EarningsItem item]);

  Future<void> remove(EarningsItem item);
}
