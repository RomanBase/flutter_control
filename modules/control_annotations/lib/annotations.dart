enum ParseIgnore {
  none,
  from,
  to,
  both,
}

enum ParseStyle {
  snake_case,
  camelCase,
  PascalCase,
}

class ParseEntity {
  final String? from;
  final String? to;
  final ParseStyle style;
  final bool copyWith;
  final bool copyFrom;
  final bool storeMixin;
  final ParseConverter? converter;

  const ParseEntity({
    this.from = '_fromJson',
    this.to = 'toJson',
    this.style = ParseStyle.snake_case,
    this.copyWith = true,
    this.copyFrom = true,
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
