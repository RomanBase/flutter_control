enum ParseIgnore {
  none,
  from,
  to,
  both,
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

class ParseEntity {
  final String? from;
  final String? to;
  final String? list;
  final String keyType;

  const ParseEntity({
    this.from = 'Json',
    this.to = 'Json',
    this.list = 'List',
    this.keyType = 'snake_case',
  });
}
