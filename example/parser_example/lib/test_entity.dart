import 'package:control_annotations/annotations.dart';
import 'package:flutter_control/control.dart';

part 'test_entity.g.dart';

enum TestEnum {
  none,
  value,
}

@ParseEntity()
class TestEntity {
  @ParseValue(key: 'id_key')
  final String id;

  final String base;

  @ParseValue(ignore: ParseIgnore.both)
  final int? count;

  final DateTime timestamp;

  final TestEnum enm;

  const TestEntity({
    required this.id,
    required this.base,
    this.count,
    required this.timestamp,
    this.enm = TestEnum.none,
  });

  factory TestEntity.fromJson(Map<String, dynamic> data) => $TestEntityFactory.fromJson(data);
}
