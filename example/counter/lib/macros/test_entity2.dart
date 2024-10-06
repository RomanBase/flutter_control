import 'package:control_macros/macros.dart';
import 'package:counter/macros/test_entity.dart';
import 'package:flutter_control/control.dart';

@ParseEntity(from: 'Json', to: 'Fire')
class TestEntity2 {
  @ParseValue(key: 'server_id', ignore: ParseIgnore.to)
  final String id;
  @ParseValue(converter: r"(data['count'] ?? 0) + 1", toConverter: 'count ?? 0')
  final int? count;
  final TestEntity? entity;
  final TestEnum enm;
  final List list;
  final List<TestEntity> testList;
  @ParseValue(key: 'str_list', converter: '(arg) => TestEntity2._convert(arg)')
  final List<String> strList;
  @ParseValue(key: 'String_Dynamic_Key', keyConverter: TestEntity2._convertEntry, converter: TestEntity2._convert)
  final Map<String, dynamic> map;
  final Map<String, TestEntity> testMap;
  final Map<String, String> strMap;
  final Map rawMap;
  @ParseValue(toConverter: _convertBackDynamic)
  final dynamic dnc;

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
    this.strMap = const {},
    this.rawMap = const {},
    this.dnc,
  });

  static String _convert(dynamic value) => Parse.toEnum(value, TestEnum.values).name;

  static String _convertEntry(dynamic key, dynamic value) => Parse.toEnum(value, TestEnum.values).name;

  static String _convertBackDynamic(dynamic value) => 'dnc $value';

  void test() {
    TestEntity2.fromJson({});
  }
}
