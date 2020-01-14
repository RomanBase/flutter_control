import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_control/core.dart';

class SpendItem {
  final String id;
  final int rank;
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
    this.rank,
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
      rank: Parse.toInteger(data['rank']) ?? 1000,
      title: Parse.string(data['title']),
      note: Parse.string(data['note']),
      value: Parse.toDouble(data['value']),
      possibleSavings: Parse.toDouble(data['saves']),
      subscription: Parse.toBool(data['sub']),
    );
  }

  Map<String, dynamic> asData() => {
        'rank': rank ?? 1000,
        'title': title,
        'note': note,
        'value': value.toDouble(),
        'saves': possibleSavings.toDouble(),
        'sub': subscription,
      };

  SpendItem withId(String id) => SpendItem(
        id: id,
        rank: rank,
        title: title,
        note: note,
        value: value,
        possibleSavings: possibleSavings,
        subscription: subscription,
      );

  static int Function(SpendItem a, SpendItem b) get byRank => (a, b) {
        if (a.rank > b.rank) {
          return 1;
        } else if (a.rank < b.rank) {
          return -1;
        }

        return 0;
      };

  static int Function(SpendItem a, SpendItem b) get byTitle => (a, b) => a.title.compareTo(b.title);

  static int Function(SpendItem a, SpendItem b) get byYearSpend => (a, b) {
        if (a.yearSpend > b.yearSpend) {
          return -1;
        } else if (a.yearSpend < b.yearSpend) {
          return 1;
        }

        return 0;
      };

  static int Function(SpendItem a, SpendItem b) get byMonthSpend => (a, b) {
        if (a.monthSpend > b.monthSpend) {
          return -1;
        } else if (a.monthSpend < b.monthSpend) {
          return 1;
        }

        return 0;
      };
}
