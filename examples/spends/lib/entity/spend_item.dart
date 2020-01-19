import 'package:flutter_control/core.dart';

enum SpendType {
  normal,
  sub,
  group,
}

extension SpendTypeExtension on SpendType {
  String asData() => this.toString().split('.')[1];

  SpendType asType(dynamic value) => value == null ? this : SpendType.values.firstWhere((item) => item.asData() == value, orElse: () => this);
}

class SpendItem {
  final String id;
  final String icon;
  final int rank;
  final String title;
  final String note;
  final num value;
  final SpendType type;
  final List<SpendItem> items;
  final String groupId;

  num get yearSpend {
    switch (type) {
      case SpendType.normal:
        return value;
      case SpendType.sub:
        return value * 12;
      case SpendType.group:
        if (items != null && items.length > 0) {
          return items.map((item) => item.yearSpend).reduce((a, b) => a + b);
        }
    }

    return value;
  }

  num get monthSpend {
    switch (type) {
      case SpendType.normal:
        return value / 12;
      case SpendType.sub:
        return value;
      case SpendType.group:
        if (items != null && items.length > 0) {
          return items.map((item) => item.monthSpend).reduce((a, b) => a + b);
        }
    }

    return 0.0;
  }

  num get subSpend {
    switch (type) {
      case SpendType.normal:
        return 0.0;
      case SpendType.sub:
        return value;
      case SpendType.group:
        if (items != null && items.length > 0) {
          return items.map((item) => item.subSpend).reduce((a, b) => a + b);
        }
    }

    return 0.0;
  }

  bool get isSub => type == SpendType.sub;

  bool get isGroup => type == SpendType.group;

  bool get hasNote => note != null && note.isNotEmpty;

  const SpendItem({
    this.id,
    this.icon,
    this.rank,
    @required this.title,
    this.note,
    this.value: 0.0,
    this.type: SpendType.normal,
    this.items,
    this.groupId,
  });

  factory SpendItem.fromData({String id, @required Map data, String groupId}) {
    return SpendItem(
      id: id,
      rank: Parse.toInteger(data['rank']) ?? 1000,
      title: Parse.string(data['title']),
      note: Parse.string(data['note']),
      value: Parse.toDouble(data['value']),
      type: SpendType.normal.asType(data['type']),
      items: Parse.toList<SpendItem>(data['items'],
          entryConverter: (key, data) => SpendItem.fromData(
                id: key.toString(),
                data: data,
                groupId: id,
              )),
      groupId: groupId,
    );
  }

  Map<String, dynamic> asData() => {
        'rank': rank ?? 1000,
        'title': title,
        'note': note,
        'value': value.toDouble(),
        'type': type.asData(),
        'items': (items != null && items.length > 0) ? items.map((item) => item.asData()).toList() : null,
      };

  SpendItem copyWith({
    String id,
    String groupId,
    String icon,
    int rank,
    String title,
    String note,
    num value,
    SpendType type,
    List<SpendItem> items,
  }) =>
      SpendItem(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        icon: icon ?? this.icon,
        rank: rank ?? this.rank,
        title: title ?? this.title,
        note: note ?? this.note,
        value: value ?? this.value,
        type: type ?? this.type,
        items: items ?? this.items,
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
