part of flutter_control;

/// A robust [ValueKey] implementation used to uniquely identify objects.
///
/// It ensures that a stable and unique key can be generated from any object,
/// which is useful for maps, widget keys, and other scenarios where object
/// identity is important.
class ObjectTag extends ValueKey {
  const ObjectTag._(super.value);

  /// Creates an [ObjectTag] from an object.
  /// If the object is already an [ObjectTag], it is returned directly.
  /// If the object is `null`, a new unique ID is generated.
  factory ObjectTag.of(Object? object) =>
      object is ObjectTag ? object : ObjectTag._(object ?? UnitId.nextId());

  /// Creates a new [ObjectTag] with a unique ID.
  factory ObjectTag.next() => ObjectTag._(UnitId.nextId());

  /// Creates a new [ObjectTag] by combining the hash code of the current tag's
  /// value with the hash code of a [variant] object. This is useful for
  /// creating unique keys for items within a list.
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
