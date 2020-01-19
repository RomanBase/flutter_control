import 'package:flutter_control/core.dart';

enum EarningsType {
  normal,
  sub,
  extra,
}

extension EarningTypeExtension on EarningsType {
  String asData() => this.toString().split('.')[1];

  EarningsType asType(dynamic value) => value == null ? this : EarningsType.values.firstWhere((item) => item.asData() == value, orElse: () => this);
}

class EarningsItem {
  final String id;
  final String icon;
  final int rank;
  final String title;
  final String note;
  final num value;
  final EarningsType type;

  num get yearEarnings {
    switch (type) {
      case EarningsType.normal:
      case EarningsType.extra:
        return value;
      case EarningsType.sub:
        return value * 12;
    }

    return 0.0;
  }

  num get monthEarnings {
    switch (type) {
      case EarningsType.normal:
      case EarningsType.extra:
        return value / 12;
      case EarningsType.sub:
        return value;
    }

    return 0.0;
  }

  num get subEarnings {
    switch (type) {
      case EarningsType.normal:
      case EarningsType.extra:
        return 0.0;
      case EarningsType.sub:
        return value;
    }

    return 0.0;
  }

  num get extraEarnings {
    switch (type) {
      case EarningsType.normal:
      case EarningsType.extra:
        return value;
      case EarningsType.sub:
        return 0.0;
    }

    return 0.0;
  }

  bool get isSub => type == EarningsType.sub;

  EarningsItem({
    this.id,
    this.icon,
    this.rank,
    this.title,
    this.note,
    this.value,
    this.type,
  });

  factory EarningsItem.fromData({String id, Map data}) {
    return EarningsItem(
      id: id,
      rank: Parse.toInteger(data['rank']) ?? 1000,
      title: Parse.string(data['title']),
      note: Parse.string(data['note']),
      value: Parse.toDouble(data['value']),
      type: EarningsType.normal.asType(data['type']),
    );
  }

  Map<String, dynamic> asData() => {
        'rank': rank ?? 1000,
        'title': title,
        'note': note,
        'value': value.toDouble(),
        'type': type.asData(),
      };

  EarningsItem copyWith({
    String id,
    String groupId,
    String icon,
    int rank,
    String title,
    String note,
    num value,
  }) =>
      EarningsItem(
        id: id ?? this.id,
        icon: icon ?? this.icon,
        rank: rank ?? this.rank,
        title: title ?? this.title,
        note: note ?? this.note,
        value: value ?? this.value,
        type: type ?? this.type,
      );

  static int Function(EarningsItem a, EarningsItem b) get byTitle => (a, b) => a.title.compareTo(b.title);
}
