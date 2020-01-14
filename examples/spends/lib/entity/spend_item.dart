import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_control/core.dart';

class SpendItem {
  final String id;
  final String title;
  final String note;
  final num value;
  final num possibleSavings;
  final bool subscription;

  num get yearSpend => subscription ? value * 12.0 : value;

  num get monthSpend => subscription ? value : value / 12.0;

  num get yearSavings => subscription ? possibleSavings * 12.0 : possibleSavings;

  num get monthSavings => subscription ? possibleSavings : possibleSavings / 12.0;

  SpendItem({
    this.id,
    @required this.title,
    this.note,
    this.value: 0.0,
    this.possibleSavings: 0.0,
    this.subscription: false,
  });

  factory SpendItem.fromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data;

    return SpendItem(
      id: snapshot.documentID,
      title: Parse.string(data['title']),
      note: Parse.string(data['note']),
      value: Parse.toDouble(data['value']),
      possibleSavings: Parse.toDouble(data['saves']),
      subscription: Parse.toBool(data['sub']),
    );
  }

  Map<String, dynamic> asData() => {
        'title': title,
        'note': note,
        'value': value.toDouble(),
        'saves': possibleSavings.toDouble(),
        'sub': subscription,
      };

  SpendItem withId(String id) => SpendItem(
        id: id,
        title: title,
        note: note,
        value: value,
        possibleSavings: possibleSavings,
        subscription: subscription,
      );
}
