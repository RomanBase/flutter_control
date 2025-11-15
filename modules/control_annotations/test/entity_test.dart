import 'package:control_annotations/annotations.dart';

@ParseEntity(converter: TestConverter())
class TestEntity {
  @ParseValue(converter: TestConverter())
  final String custom;

  @TestValue('key')
  final String custom2;

  const TestEntity(
    this.custom,
    this.custom2,
  );
}

@TestParser()
class TestEntity2 {}

class TestConverter extends ParseConverter {
  const TestConverter();

  @override
  dynamic from(dynamic data) => data;

  @override
  dynamic to(dynamic data) => data;
}

class TestParser extends ParseEntity {
  const TestParser() : super(converter: const TestConverter());
}

class TestValue extends ParseValue {
  const TestValue(String key)
      : super(key: key, converter: const TestConverter());
}
