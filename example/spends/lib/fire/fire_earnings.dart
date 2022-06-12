import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_control/control.dart';
import 'package:spends/data/earnings_repo.dart';
import 'package:spends/entity/earnings_item.dart';

import 'fire_db.dart';

class FireEarningsRepo extends FireDB implements EarningsRepo {
  CollectionReference earningsRef() => dataRef().collection('earnings');

  DocumentReference earningRef(String itemId) => earningsRef().doc(itemId);

  @override
  Future<List<EarningsItem>> getEarnings() async {
    final result = await earningsRef().get();

    return Parse.toList<EarningsItem>(result.docs, converter: (snapshot) {
      if (snapshot is DocumentSnapshot && snapshot.exists) {
        return EarningsItem.fromData(
          id: snapshot.id,
          data: snapshot.data(),
        );
      }

      return null;
    });
  }

  @override
  Future<EarningsItem> add(EarningsItem item) async {
    final result = await earningsRef().add(item.asData());

    return item.copyWith(id: result.id);
  }

  @override
  Future<EarningsItem> update(EarningsItem origin, [EarningsItem item]) async {
    assert(origin.id != null);
    item ??= origin;

    await earningRef(origin.id).set(item.asData());

    return item.copyWith(id: origin.id);
  }

  @override
  Future<void> remove(EarningsItem item) {
    assert(item.id != null);

    return earningRef(item.id).delete();
  }
}
