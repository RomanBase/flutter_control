import 'package:control_macros/macros.dart';
import 'package:counter/macros_test/test_entity.dart';

@ParseEntity()
class TestEntity2 {
  final String id;
  final int? count;
  final TestEntity? entity;
  final TestEnum enm;

  const TestEntity2({
    required this.id,
    this.count,
    this.entity,
    this.enm = TestEnum.none,
  });

  void test() {
    TestEntity2.fromJson({});
  }
}
