// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'test_entity2.dart';

// **************************************************************************
// ParseGenerator
// **************************************************************************

AbsEntity _fromJson(Map<String, dynamic> data) => AbsEntity(
      abc: Parse.string(data['abc']),
      timestamp: Parse.date(data['timestamp']),
      timestamp2: data['timestamp2'],
      timestamp3: Parse.date(data['timestamp3']),
    );

extension AbsEntityFactory on AbsEntity {
  Map<String, dynamic> toJson() => {
        'abc': abc,
        'timestamp': timestamp?.toIso8601String(),
        'timestamp2': timestamp2,
        'timestamp3': timestamp3?.toIso8601String(),
      };

  AbsEntity copyWith({
    String? abc,
    DateTime? timestamp,
    DateTime? timestamp2,
    DateTime? timestamp3,
  }) =>
      AbsEntity(
        abc: abc ?? this.abc,
        timestamp: timestamp ?? this.timestamp,
        timestamp2: timestamp2 ?? this.timestamp2,
        timestamp3: timestamp3 ?? this.timestamp3,
      );

  AbsEntity copyFromJson(Map<String, dynamic> data) => AbsEntity(
        abc: data.containsKey('abc') ? Parse.string(data['abc']) : abc,
        timestamp: data.containsKey('timestamp')
            ? Parse.date(data['timestamp'])
            : timestamp,
        timestamp2: data['timestamp2'] ?? timestamp2,
        timestamp3: data.containsKey('timestamp3')
            ? Parse.date(data['timestamp3'])
            : timestamp3,
      );
}

mixin AbsEntityStore {
  late AbsEntity absEntity;

  @protected
  void onUpdateAbsEntity(Map<String, dynamic> data);

  void updateAbsEntityFromJson(Map<String, dynamic> data) {
    absEntity = absEntity.copyFromJson(data);

    if (this is ObservableNotifier) {
      (this as ObservableNotifier).notify();
    }
  }

  void updateAbsEntity({
    String? abc,
    DateTime? timestamp,
    DateTime? timestamp2,
    DateTime? timestamp3,
  }) {
    final data = {
      if (abc != null) 'abc': abc,
      if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
      if (timestamp2 != null) 'timestamp2': timestamp2,
      if (timestamp3 != null) 'timestamp3': timestamp3.toIso8601String(),
    };

    absEntity = absEntity.copyWith(
      abc: abc,
      timestamp: timestamp,
      timestamp2: timestamp2,
      timestamp3: timestamp3,
    );

    onUpdateAbsEntity(data);

    if (this is ObservableNotifier) {
      (this as ObservableNotifier).notify();
    }
  }
}

TestEntity2 _fromFire(Map<String, dynamic> data) => TestEntity2(
      abc: Parse.string(data['Abc']),
      timestamp2: data['Timestamp2'],
      timestamp3: Parse.date(data['Timestamp3']),
      id: Parse.string(data['server_id']),
      count: Parse.toInteger(data['Count']),
      entity: TestEntity.fromJson(data['Entity']),
      entity2: data.containsKey('Entity2')
          ? TestEntity.fromJson(data['Entity2'])
          : null,
      enm: Parse.toEnum(data['Enm'], TestEnum.values),
      list: Parse.toList(data['List'], converter: (item) => item),
      testList: Parse.toList(data['TestList'],
          converter: (item) => TestEntity.fromJson(item)),
      strList: Parse.toList(data['str_list'], converter: (item) => item),
      map: Parse.toKeyMap(data['String_Dynamic_Key'], (key, value) => key,
          converter: (value) => value),
      testMap: Parse.toKeyMap(
          data['TestMap'], (key, value) => Parse.string(key),
          converter: (value) => TestEntity.fromJson(value)),
      testEnumMap: Parse.toKeyMap(data['TestEnumMap'],
          (key, value) => Parse.toEnum(key, TestEnum.values),
          converter: (value) => Parse.toEnum(value, TestEnum.values)),
      strMap: Parse.toKeyMap(data['StrMap'], (key, value) => Parse.string(key),
          converter: (value) => value),
      rawMap: data['RawMap'],
      dnc: data['dynamic'] ?? "#",
      absEntity: data.containsKey('AbsEntity')
          ? AbsEntity.fromJson(data['AbsEntity'])
          : null,
    );

extension TestEntity2Factory on TestEntity2 {
  Map<String, dynamic> toFire() => {
        'Abc': abc,
        'Timestamp': timestamp?.toIso8601String(),
        'Timestamp2': timestamp2,
        'Timestamp3': timestamp3?.toIso8601String(),
        'Count': count,
        'Entity': entity.toJson(),
        'Entity2': entity2?.toJson(),
        'Enm': enm.name,
        'List': list,
        'TestList': testList.map((e) => e.toJson()).toList(),
        'str_list': strList,
        'String_Dynamic_Key': map,
        'TestMap': testMap.map((key, value) => MapEntry(key, value.toJson())),
        'TestEnumMap':
            testEnumMap.map((key, value) => MapEntry(key, value.name)),
        'StrMap': strMap,
        'RawMap': rawMap,
        'dynamic': dnc,
        'AbsEntity': absEntity?.toJson(),
      };

  TestEntity2 copyWith({
    String? abc,
    DateTime? timestamp2,
    DateTime? timestamp3,
    String? id,
    int? count,
    TestEntity? entity,
    TestEntity? entity2,
    TestEnum? enm,
    List<dynamic>? list,
    List<TestEntity>? testList,
    List<String>? strList,
    Map<Object, dynamic>? map,
    Map<String, TestEntity>? testMap,
    Map<TestEnum, TestEnum>? testEnumMap,
    Map<String, String>? strMap,
    Map<dynamic, dynamic>? rawMap,
    dynamic toIgnore,
    dynamic dnc,
    AbsEntity? absEntity,
  }) =>
      TestEntity2(
        abc: abc ?? this.abc,
        timestamp2: timestamp2 ?? this.timestamp2,
        timestamp3: timestamp3 ?? this.timestamp3,
        id: id ?? this.id,
        count: count ?? this.count,
        entity: entity ?? this.entity,
        entity2: entity2 ?? this.entity2,
        enm: enm ?? this.enm,
        list: list ?? this.list,
        testList: testList ?? this.testList,
        strList: strList ?? this.strList,
        map: map ?? this.map,
        testMap: testMap ?? this.testMap,
        testEnumMap: testEnumMap ?? this.testEnumMap,
        strMap: strMap ?? this.strMap,
        rawMap: rawMap ?? this.rawMap,
        toIgnore: toIgnore ?? this.toIgnore,
        dnc: dnc ?? this.dnc,
        absEntity: absEntity ?? this.absEntity,
      );

  TestEntity2 copyFromFire(Map<String, dynamic> data) => TestEntity2(
        abc: data.containsKey('Abc') ? Parse.string(data['Abc']) : abc,
        timestamp2: data['Timestamp2'] ?? timestamp2,
        timestamp3: data.containsKey('Timestamp3')
            ? Parse.date(data['Timestamp3'])
            : timestamp3,
        id: data.containsKey('server_id')
            ? Parse.string(data['server_id'])
            : id,
        count:
            data.containsKey('Count') ? Parse.toInteger(data['Count']) : count,
        entity: data.containsKey('Entity')
            ? TestEntity.fromJson(data['Entity'])
            : entity,
        entity2: data.containsKey('Entity2')
            ? TestEntity.fromJson(data['Entity2'])
            : entity2,
        enm: data.containsKey('Enm')
            ? Parse.toEnum(data['Enm'], TestEnum.values)
            : enm,
        list: data.containsKey('List')
            ? Parse.toList(data['List'], converter: (item) => item)
            : list,
        testList: data.containsKey('TestList')
            ? Parse.toList(data['TestList'],
                converter: (item) => TestEntity.fromJson(item))
            : testList,
        strList: data.containsKey('str_list')
            ? Parse.toList(data['str_list'], converter: (item) => item)
            : strList,
        map: data.containsKey('String_Dynamic_Key')
            ? Parse.toKeyMap(data['String_Dynamic_Key'], (key, value) => key,
                converter: (value) => value)
            : map,
        testMap: data.containsKey('TestMap')
            ? Parse.toKeyMap(data['TestMap'], (key, value) => Parse.string(key),
                converter: (value) => TestEntity.fromJson(value))
            : testMap,
        testEnumMap: data.containsKey('TestEnumMap')
            ? Parse.toKeyMap(data['TestEnumMap'],
                (key, value) => Parse.toEnum(key, TestEnum.values),
                converter: (value) => Parse.toEnum(value, TestEnum.values))
            : testEnumMap,
        strMap: data.containsKey('StrMap')
            ? Parse.toKeyMap(data['StrMap'], (key, value) => Parse.string(key),
                converter: (value) => value)
            : strMap,
        rawMap: data['RawMap'] ?? rawMap,
        dnc: data['dynamic'] ?? dnc,
        absEntity: data.containsKey('AbsEntity')
            ? AbsEntity.fromJson(data['AbsEntity'])
            : absEntity,
      );
}

mixin TestEntity2Store {
  late TestEntity2 testEntity2;

  @protected
  void onUpdateTestEntity2(Map<String, dynamic> data);

  void updateTestEntity2FromFire(Map<String, dynamic> data) {
    testEntity2 = testEntity2.copyFromFire(data);

    if (this is ObservableNotifier) {
      (this as ObservableNotifier).notify();
    }
  }

  void updateTestEntity2({
    String? abc,
    DateTime? timestamp2,
    DateTime? timestamp3,
    String? id,
    int? count,
    TestEntity? entity,
    TestEntity? entity2,
    TestEnum? enm,
    List<dynamic>? list,
    List<TestEntity>? testList,
    List<String>? strList,
    Map<Object, dynamic>? map,
    Map<String, TestEntity>? testMap,
    Map<TestEnum, TestEnum>? testEnumMap,
    Map<String, String>? strMap,
    Map<dynamic, dynamic>? rawMap,
    dynamic toIgnore,
    dynamic dnc,
    AbsEntity? absEntity,
  }) {
    final data = {
      if (abc != null) 'Abc': abc,
      if (timestamp2 != null) 'Timestamp2': timestamp2,
      if (timestamp3 != null) 'Timestamp3': timestamp3.toIso8601String(),
      if (count != null) 'Count': count,
      if (entity != null) 'Entity': entity.toJson(),
      if (entity2 != null) 'Entity2': entity2.toJson(),
      if (enm != null) 'Enm': enm.name,
      if (list != null) 'List': list,
      if (testList != null)
        'TestList': testList.map((e) => e.toJson()).toList(),
      if (strList != null) 'str_list': strList,
      if (map != null) 'String_Dynamic_Key': map,
      if (testMap != null)
        'TestMap': testMap.map((key, value) => MapEntry(key, value.toJson())),
      if (testEnumMap != null)
        'TestEnumMap':
            testEnumMap.map((key, value) => MapEntry(key, value.name)),
      if (strMap != null) 'StrMap': strMap,
      if (rawMap != null) 'RawMap': rawMap,
      if (dnc != null) 'dynamic': dnc,
      if (absEntity != null) 'AbsEntity': absEntity.toJson(),
    };

    testEntity2 = testEntity2.copyWith(
      abc: abc,
      timestamp2: timestamp2,
      timestamp3: timestamp3,
      id: id,
      count: count,
      entity: entity,
      entity2: entity2,
      enm: enm,
      list: list,
      testList: testList,
      strList: strList,
      map: map,
      testMap: testMap,
      testEnumMap: testEnumMap,
      strMap: strMap,
      rawMap: rawMap,
      toIgnore: toIgnore,
      dnc: dnc,
      absEntity: absEntity,
    );

    onUpdateTestEntity2(data);

    if (this is ObservableNotifier) {
      (this as ObservableNotifier).notify();
    }
  }
}
