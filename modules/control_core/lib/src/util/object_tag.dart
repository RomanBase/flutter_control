part of '../../core.dart';

class ObjectTag {
  final Object? value;

  ValueKey get key => ValueKey(value);

  const ObjectTag._(this.value);

  factory ObjectTag.of(Object? object) =>
      object is ObjectTag ? object : ObjectTag._(object ?? UnitId.nextId());

  factory ObjectTag.next() => ObjectTag._(UnitId.nextId());

  ObjectTag variant(Object variant) =>
      ObjectTag._(value.hashCode ^ variant.hashCode);

  @override
  bool operator ==(Object other) {
    return other is ObjectTag && value == other.value;
  }

  @override
  int get hashCode => value?.hashCode ?? super.hashCode;

  @override
  String toString() {
    return 'tag: $hashCode';
  }
}
