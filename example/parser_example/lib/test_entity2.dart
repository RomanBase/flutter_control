import 'package:control_annotations/annotations.dart';
import 'package:flutter_control/control.dart';
import 'package:parser_example/test_entity.dart';

part 'test_entity2.g.dart';

class AbsEntity {
  final String abc;
  final DateTime? timestamp;

  @ParseValue(raw: true)
  final DateTime? timestamp2;

  final DateTime? timestamp3;

  const AbsEntity({
    required this.abc,
    this.timestamp,
    this.timestamp2,
    this.timestamp3,
  });
}

@ParseEntity(from: 'Fire', to: 'Fire')
class TestEntity2 extends AbsEntity {
  @ParseValue(key: 'server_id', ignore: ParseIgnore.to)
  final String id;

  final int count;
  final TestEntity entity;
  final TestEntity? entity2;
  final TestEnum enm;
  final List list;
  final List<TestEntity> testList;

  @ParseValue(key: 'str_list')
  final List<String> strList;

  @ParseValue(key: 'String_Dynamic_Key')
  final Map<Object, dynamic> map;

  final Map<String, TestEntity> testMap;
  final Map<TestEnum, TestEnum> testEnumMap;
  final Map<String, String>? strMap;

  @ParseValue(raw: true)
  final Map? rawMap;

  @ParseValue(ignore: ParseIgnore.both)
  final dynamic toIgnore;

  @ParseValue(key: 'dynamic', defaultValue: '"#"')
  final dynamic dnc;

  String get dncGetter => '$dnc';

  set dncSetter(dynamic value) {}

  final String dncDefault = '#';

  const TestEntity2({
    required super.abc,
    required this.id,
    this.count = 0,
    required this.entity,
    this.entity2,
    this.enm = TestEnum.none,
    this.list = const [],
    this.testList = const [],
    this.strList = const [],
    this.map = const {},
    this.testMap = const {},
    this.testEnumMap = const {},
    this.strMap = const {},
    this.rawMap,
    this.dnc,
    this.toIgnore,
    //timestamp missing
    super.timestamp2,
    super.timestamp3,
  });

  factory TestEntity2.fromJson(Map<String, dynamic> data) => _fromFire(data);
}
