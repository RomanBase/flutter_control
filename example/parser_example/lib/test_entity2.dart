import 'package:control_annotations/annotations.dart';
import 'package:flutter_control/control.dart';
import 'package:parser_example/test_entity.dart';

part 'test_entity2.g.dart';

@ParseEntity(from: 'Fire', to: 'Fire')
class TestEntity2 {
  @ParseValue(key: 'server_id', ignore: ParseIgnore.to)
  final String id;

  final int? count;
  final TestEntity? entity;
  final TestEnum enm;
  final List list;
  final List<TestEntity> testList;

  @ParseValue(key: 'str_list')
  final List<String> strList;

  @ParseValue(key: 'String_Dynamic_Key')
  final Map<Object, dynamic> map;

  final Map<String, TestEntity> testMap;
  final Map<TestEnum, TestEnum> testEnumMap;
  final Map<String, String> strMap;

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
    required this.id,
    this.count,
    this.entity,
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
  });

  factory TestEntity2.fromJson(Map<String, dynamic> data) => TestEntity2Factory.fromFire(data);
}
