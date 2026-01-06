// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'test_entity.dart';

// **************************************************************************
// ParseGenerator
// **************************************************************************

TestEntity _fromJson(Map<String, dynamic> data) => TestEntity(
      id: Parse.string(data['id_key']),
      base: Parse.string(data['base']),
      timestamp: Parse.date(data['timestamp'])!,
      time2: Parse.date(data['time2']),
      enm: Parse.toEnum(data['enm'], TestEnum.values),
    );

extension TestEntityFactory on TestEntity {
  Map<String, dynamic> toJson() => {
        'id_key': id,
        'base': base,
        'timestamp': timestamp.toIso8601String(),
        'time2': time2?.toIso8601String(),
        'enm': enm.name,
      };

  TestEntity copyWith({
    String? id,
    String? base,
    int? count,
    DateTime? timestamp,
    DateTime? time2,
    TestEnum? enm,
  }) =>
      TestEntity(
        id: id ?? this.id,
        base: base ?? this.base,
        count: count ?? this.count,
        timestamp: timestamp ?? this.timestamp,
        time2: time2 ?? this.time2,
        enm: enm ?? this.enm,
      );

  TestEntity copyFromJson(Map<String, dynamic> data) => TestEntity(
        id: data.containsKey('id_key') ? Parse.string(data['id_key']) : id,
        base: data.containsKey('base') ? Parse.string(data['base']) : base,
        timestamp: data.containsKey('timestamp')
            ? Parse.date(data['timestamp'])!
            : timestamp,
        time2: data.containsKey('time2') ? Parse.date(data['time2']) : time2,
        enm: data.containsKey('enm')
            ? Parse.toEnum(data['enm'], TestEnum.values)
            : enm,
      );
}

mixin TestEntityStore {
  late TestEntity testEntity;

  @protected
  void onUpdateTestEntity(Map<String, dynamic> data);

  void updateTestEntityFromJson(Map<String, dynamic> data) {
    testEntity = testEntity.copyFromJson(data);

    if (this is ObservableNotifier) {
      (this as ObservableNotifier).notify();
    }
  }

  void updateTestEntity({
    String? id,
    String? base,
    int? count,
    DateTime? timestamp,
    DateTime? time2,
    TestEnum? enm,
  }) {
    final data = {
      if (id != null) 'id_key': id,
      if (base != null) 'base': base,
      if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
      if (time2 != null) 'time2': time2.toIso8601String(),
      if (enm != null) 'enm': enm.name,
    };

    testEntity = testEntity.copyWith(
      id: id,
      base: base,
      count: count,
      timestamp: timestamp,
      time2: time2,
      enm: enm,
    );

    onUpdateTestEntity(data);

    if (this is ObservableNotifier) {
      (this as ObservableNotifier).notify();
    }
  }
}
