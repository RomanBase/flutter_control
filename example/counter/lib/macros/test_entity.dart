import 'package:control_macros/macros.dart';
import 'package:flutter_control/control.dart';

enum TestEnum {
  none,
  value;

  static TestEnum fromJson(Map<String, dynamic> data) => Parse.toEnum(data, values);

  String toJson() => name;
}

@ParseEntity()
class TestEntity extends BaseEntity {
  @ParseValue(key: 'id_key')
  final String id;

  @ParseIgnore()
  final int? count;

  final DateTime timestamp;

  const TestEntity({
    required super.base,
    required this.id,
    this.count,
    required this.timestamp,
    super.enm = TestEnum.none,
  });

  void test() {
    TestEntity.fromJson({});
  }
}

class BaseEntity {
  final String base;
  final TestEnum enm;

  const BaseEntity({
    required this.base,
    required this.enm,
  });
}
