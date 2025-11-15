import 'package:flutter/material.dart';
import 'package:parser_example/test_entity.dart';
import 'package:parser_example/test_entity2.dart';

void main() {
  TestEntity.fromJson({})
    ..copyFromJson({})
    ..copyWith()
    ..toJson();

  TestEntity2.fromJson({})
    ..copyFromFire({})
    ..copyWith()
    ..toFire();
}
