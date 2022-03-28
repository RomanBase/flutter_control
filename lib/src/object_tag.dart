import 'package:flutter_control/core.dart';

class ObjectTag {
  final Object? value;

  ValueKey get key => ValueKey(this.value);

  const ObjectTag._(this.value);

  factory ObjectTag.of(Object? object) =>
      object is ObjectTag ? object : ObjectTag._(object ?? UnitId.nextId());

  factory ObjectTag.next() => ObjectTag._(UnitId.nextId());

  factory ObjectTag.key(Key? key) {
    Object? object;

    if (key != null) {
      if (key is ObjectKey) {
        object = key.value;
      } else if (key is ValueKey) {
        object = key.value;
      } else if (key is GlobalObjectKey) {
        object = key.value;
      } else {
        object = key;
      }
    }

    return ObjectTag.of(object);
  }

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

extension KeyExt on Key {
  ValueKey variant(Object value) => ObjectTag.key(this).variant(value).key;
}
