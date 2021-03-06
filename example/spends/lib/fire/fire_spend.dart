import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_control/core.dart';
import 'package:spends/data/spend_repo.dart';
import 'package:spends/entity/spend_item.dart';

import 'fire_db.dart';

class FireSpendRepo extends FireDB implements SpendRepo {
  CollectionReference spendsRef() => dataRef().collection('spends');

  DocumentReference spendRef(String itemId) => spendsRef().document(itemId);

  @override
  Future<List<SpendItem>> getSpends() async {
    final result = await spendsRef().getDocuments();

    return Parse.toList<SpendItem>(result.documents, converter: (snapshot) {
      if (snapshot is DocumentSnapshot && snapshot.exists) {
        return SpendItem.fromData(
          id: snapshot.documentID,
          data: snapshot.data,
        );
      }

      return null;
    });
  }

  @override
  Future<SpendItem> add(SpendItem item) async {
    final result = await spendsRef().add(item.asData());

    return item.copyWith(id: result.documentID);
  }

  @override
  Future<SpendItem> update(SpendItem origin, [SpendItem item]) async {
    assert(origin.id != null);
    item ??= origin;

    await spendRef(origin.id).setData(item.asData());

    return item.copyWith(id: origin.id);
  }

  @override
  Future<void> remove(SpendItem item) async {
    assert(item.id != null);

    return spendRef(item.id).delete();
  }
}
