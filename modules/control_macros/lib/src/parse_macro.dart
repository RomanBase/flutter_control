import 'dart:async';

import 'package:macros/macros.dart';
import 'package:control_core/core.dart';

enum ParseIgnore {
  none,
  from,
  to,
  both,
}

// some magic shit with ref or static analysis bug
// TODO: convert back to enum
class _KeyType {
  const _KeyType._();

  static const origin = 'origin';
  static const snake_case = 'snake_case';
  static const camelCase = 'camelCase';
  static const CamelCase = 'CamelCase';
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

macro class ParseEntity implements ClassDeclarationsMacro {
  final String? from;
  final String? to;
  final String keyType;

  const ParseEntity({
    this.from = 'Json',
    this.to = 'Json',
    this.keyType = 'snake_case',
  });

  Future<List<_Field>> _getFields(TypeDeclaration declaration, MemberDeclarationBuilder builder) async {
    final items = (await builder.fieldsOf(declaration)).map((e) => _Field(declaration: e)).toList();

    if (declaration is ClassDeclaration && declaration.superclass != null) {
      final superClass = await builder.typeDeclarationOf(declaration.superclass!.identifier);
      final superItems = await _getFields(superClass, builder);
      return [...items, ...superItems];
    }

    return items;
  }

  Future<List<_Method>> _getMethods(TypeDeclaration declaration, MemberDeclarationBuilder builder) async {
    final items = (await builder.methodsOf(declaration)).map((e) => _Method(declaration: e)).toList();

    if (declaration is ClassDeclaration && declaration.superclass != null) {
      final superClass = await builder.typeDeclarationOf(declaration.superclass!.identifier);
      final superItems = await _getMethods(superClass, builder);
      return [...items, ...superItems];
    }

    return items;
  }

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final fields = await _getFields(clazz, builder);
    final methods = await _getMethods(clazz, builder);

    builder.declareInLibrary(DeclarationCode.fromString('import \'package:control_core/core.dart\';'));
    builder.declareInLibrary(DeclarationCode.fromString(''));

    if (from != null) {
      builder.declareInType(DeclarationCode.fromParts([
        'factory ${clazz.identifier.name}.from$from(Map<String, dynamic> data) => ${clazz.identifier.name}(\n',
        ...fields.where((e) => !e.ignoreFrom).map((e) => _buildParse(e, methods)).reduce((a, b) => [...a, DeclarationCode.fromString(',\n'), ...b]),
        '\n);',
      ]));
    }

    if (to != null) {
      builder.declareInType(DeclarationCode.fromString(''));
      builder.declareInType(DeclarationCode.fromParts([
        'Map<String, dynamic> to$to() => {\n',
        ...fields.where((e) => !e.ignoreTo).map((e) => '${_key(e.key, e.customKey)}: ${_jsonValue(e, methods)},\n'),
        '};',
      ]));
    }
  }

  Iterable _buildParse(_Field field, List<_Method> methods) {
    final key = _key(field.key, field.customKey);

    if (field.raw) {
      return ['${field.name}: data[$key]'];
    }

    if (field.fromConverter != null) {
      return ['${field.name}: ${field.fromConverter}'];
    }

    if (field.type.startsWith('List')) {
      if (field.isArgDynamic(0)) {
        return ['${field.name}: Parse.toList(data[$key])'];
      }

      return [
        '${field.name}: Parse.toList(data[$key]',
        if(field.converter == null && field.keyConverter == null && !field.isArgPrimitive(0))
          ...[', converter: (data) => ', field.getArg(0), '.fromJson(data)'],
        if(field.converter != null)
          ...[', converter: ', field.converter],
        if(field.entryConverter != null)
          ...[', entryConverter: ', field.entryConverter],
        ')',
      ];
    } else if (field.type.startsWith('Map')) {
      if (field.isArgDynamic(0) && field.isArgDynamic(1)) {
        return ['${field.name}: Parse.toMap(data[$key])'];
      }

      return [
        '${field.name}: Parse.toKeyMap(data[$key],',
        field.keyConverter ?? '(key, value) => \'\$key\'',
        if(field.converter == null && field.keyConverter == null && !field.isArgPrimitive(1))
          ...[', converter: (data) => ', field.getArg(1), '.fromJson(data)'],
        if(field.converter != null)
          ...[', converter: ', field.converter],
        if(field.entryConverter != null)
          ...[', entryConverter: ', field.entryConverter],
        ')',
      ];
    } else if (field.type.startsWith('DateTime')) {
      return ['${field.name}: Parse.date(data[$key])${field.nullable ? '' : '!'}'];
    }

    return _parseObject(field, key);
  }

  Iterable _parseObject(_Field field, String key) {
    if (field.isDynamic()) {
      return ['${field.name}: data[$key]'];
    }

    if (field.isPrimitive()) {
      if (field.nullable) {
        return ['${field.name}: ParseN.${_parseFunction(field.type, key, field.defaultValue)}'];
      }

      return ['${field.name}: Parse.${_parseFunction(field.type, key, field.defaultValue)}'];
    }

    return ['${field.name}: ', field.obj.identifier, '.fromJson(data[$key])'];
  }

  String _parseFunction(String type, dynamic key, [dynamic value]) =>
      switch(type.toLowerCase()) {
        'string' => 'string(data[$key]${_defaultValue(value)})',
        'int' => 'toInteger(data[$key]${_defaultValue(value)})',
        'double' => 'toDouble(data[$key]${_defaultValue(value)})',
        'number' => 'toDouble(data[$key]${_defaultValue(value)})',
        'bool' => 'toBool(data[$key]${_defaultValue(value)})',
        _ => 'toDynamic(data[$key])', // no such method
      };

  String _defaultValue(dynamic defaultValue) => defaultValue == null ? '' : ', defaultValue: $defaultValue';

  String _jsonValue(_Field field, List<_Method> methods) {
    final convert = field.toConverter;

    if (convert != null) {
      final method = methods.find<_Method>((value) => value.name == convert);

      if (method != null) {
        return '${method.name}(${method.hasParams ? field.name : ''})';
      }

      return convert;
    }

    if (field.isPrimitive()) {
      return field.name;
    }

    if (field.type == 'List') {
      if (field.isArgPrimitive(0)) {
        return field.name;
      }

      return '${field.name}.map((e) => e.toJson())';
    } else if (field.type == 'Map') {
      if (field
          .getArg(0)
          ?.name == 'String' && field.isArgPrimitive(1)) {
        return field.name;
      }

      return '${field.name}.map((key, value) => MapEntry(${field
          .getArg(0)
          ?.name == 'String' ? 'key' : '\'\$key\''}, value${field.isArgPrimitive(1) ? '' : '.toJson()'}))';
    }

    return '${field.name}${field.nullable ? '?' : ''}.toJson()';
  }

  String _key(String value, bool custom) =>
      switch(custom ? _KeyType.origin : keyType){
        _KeyType.snake_case => _snake(value),
        _KeyType.camelCase => _camel(value, false),
        _KeyType.CamelCase => _camel(value, true),
        _ => value,
      };

  String _snake(String value) {
    final lower = value.toLowerCase();

    String output = '';
    for (int i = 0; i < value.length; i++) {
      final char = lower[i];

      output += char == value[i] ? char : '_$char';
    }

    return output;
  }

  //this should be by default Dart formating
  String _camel(String value, bool capitalize) {
    if (capitalize) {
      return '${value.substring(0, 2).toUpperCase()}${value.substring(2)}';
    }

    return value;
  }
}

class _Field {
  final FieldDeclaration declaration;
  late final NamedTypeAnnotation obj;

  ConstructorMetadataAnnotation? annotation;

  Map<String, ExpressionCode> args = {};

  _Field({
    required this.declaration,
  }) {
    obj = declaration.type as NamedTypeAnnotation;

    for (final ann in declaration.metadata) {
      if (ann is ConstructorMetadataAnnotation) {
        if (ann.type.identifier.name == 'ParseValue') {
          annotation = ann;
        }

        if (ann.type.identifier.name.startsWith('Parse')) {
          args.addAll(ann.namedArguments);
        }
      }
    }
  }

  String get name => declaration.identifier.name;

  String get type => obj.identifier.name;

  bool get nullable => obj.isNullable;

  bool get customKey => args.containsKey('key');

  dynamic get key => args['key']?.parts.first ?? '\'$name\'';

  dynamic get defaultValue => args['defaultValue']?.parts.first;

  bool get ignoreFrom => _ignore(ParseIgnore.from);

  bool get ignoreTo => _ignore(ParseIgnore.to);

  bool get raw => args['raw']?.parts.first == 'true';

  String? get keyConverter => _unwrap(args['keyConverter']?.parts.first);

  String? get converter => _unwrap(args['converter']?.parts.first);

  String? get entryConverter => _unwrap(args['entryConverter']?.parts.first);

  String? get fromConverter => _unwrap(args['fromConverter']?.parts.first) ?? (isPrimitive() ? converter : null);

  String? get toConverter => _unwrap(args['toConverter']?.parts.first);

  String? _unwrap(Object? value) {
    if (value is String) {
      final raw = (value.startsWith('r\'') || value.startsWith('r"'));
      if (raw || (value.startsWith('\'') && value.endsWith('\'')) || (value.startsWith('"') && value.endsWith('"'))) {
        return value.substring(raw ? 2 : 1, value.length - 1);
      }

      return value;
    }

    return value?.toString();
  }

  bool _ignore(ParseIgnore toIgnore) {
    final ignore = args['ignore']?.parts.first;

    return ignore == 'ParseIgnore.both' || ignore == 'ParseIgnore.${toIgnore.name}';
  }

  bool _isPrimitive(String? type) {
    return _isDynamic(type) || type == 'void' || type == 'String' || type == 'int' || type == 'double' || type == 'number' || type == 'bool' || type == 'DateTime';
  }

  bool _isDynamic(String? type) => type == null || type == 'dynamic';

  bool isPrimitive() => _isPrimitive(type);

  bool isDynamic() => _isDynamic(type);

  bool isArgPrimitive(int index) => _isPrimitive(getArg(index)?.name);

  bool isArgDynamic(int index) => _isDynamic(getArg(index)?.name);

  Identifier? getArg(int index) {
    if (obj.typeArguments.length <= index) {
      return null;
    }

    return (obj.typeArguments.elementAt(index) as NamedTypeAnnotation).identifier;
  }
}

class _Method {
  final MethodDeclaration declaration;

  _Method({
    required this.declaration
  });

  String get name => declaration.identifier.name;

  bool get hasParams => declaration.positionalParameters.isNotEmpty;
}