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

  const ParseEntity({
    this.from = 'Json',
    this.to = 'Json',
    this.keyType = 'snake_case',
    this.copyWith = true,
    this.copyWithData = true,
  });
}

class ParseValue<T> {
  final String? key;
  final bool raw;
  final T? defaultValue;
  final ParseIgnore ignore;
  final dynamic keyConverter;
  final dynamic converter;
  final dynamic entryConverter;
  final dynamic fromConverter;
  final dynamic toConverter;

  const ParseValue({
    this.key,
    this.raw = false,
    this.defaultValue,
    this.ignore = ParseIgnore.none,
    this.keyConverter,
    this.converter,
    this.entryConverter,
    this.fromConverter,
    this.toConverter,
  });
}
