enum ParseIgnore {
  none,
  from,
  to,
  both,
}

class ParseEntity {
  final String? from;
  final String? to;
  final String keyType;
  final bool copyWith;
  final bool copyWithData;
  final bool storeMixin;
  final ParseConverter? converter;

  const ParseEntity({
    this.from = '_fromJson',
    this.to = 'toJson',
    this.keyType = 'snake_case',
    this.copyWith = true,
    this.copyWithData = true,
    this.storeMixin = true,
    this.converter,
  });
}

class ParseValue<T> {
  final String? key;
  final bool raw;
  final T? defaultValue;
  final ParseIgnore ignore;
  final ParseConverter? converter;

  const ParseValue({
    this.key,
    this.raw = false,
    this.defaultValue,
    this.ignore = ParseIgnore.none,
    this.converter,
  });
}

abstract class ParseConverter<T, U> {
  const ParseConverter();

  T from(U data);

  U to(T data);
}
