/*
import 'dart:async';

import 'package:macros/macros.dart';
import 'package:control_core/core.dart';

import 'declarations.dart';

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

//TODO: not working?
macro class ParseEnum implements EnumDeclarationsMacro {
  const ParseEnum();

  @override
  FutureOr<void> buildDeclarationsForEnum(EnumDeclaration enuum, EnumDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromString('String toJson() => name;'));
    builder.declareInType(DeclarationCode.fromString('static TestEnum fromJson(Map<String, dynamic> data) => Parse.toEnum(data, values);'));
  }
}

macro class ParseEntity implements ClassDeclarationsMacro {
  final String? from;
  final String? to;
  final String? list;
  final String keyType;

  //Only named params are supported right now
  const ParseEntity({
    this.from = 'Json',
    this.to = 'Json',
    this.list = 'List',
    this.keyType = 'snake_case',
  });

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final fields = await MacroField.getFields(clazz, builder);
    final methods = await MacroMethod.getMethods(clazz, builder);

    builder.declareInLibrary(DeclarationCode.fromString('import \'package:control_core/core.dart\';'));
    builder.declareInLibrary(DeclarationCode.fromString('\n'));

    if (list != null) {
      builder.declareInType(DeclarationCode.fromParts([
        'static List<${clazz.identifier.name}> to$list(dynamic data) => Parse.toList(data, converter: (data) => ${clazz.identifier.name}.from$from(data));',
        '\n'
      ]));
    }

    if (from != null) {
      builder.declareInType(DeclarationCode.fromParts([
        'factory ${clazz.identifier.name}.from$from(Map<String, dynamic> data) => ${clazz.identifier.name}(\n',
        ...fields.where((e) => !e.ignoreFrom).map((e) => _buildParse(e, methods)).reduce((a, b) => [...a, DeclarationCode.fromString(',\n'), ...b]),
        '\n);',
      ]));
    }

    if (to != null) {
      builder.declareInType(DeclarationCode.fromString('\n'));
      builder.declareInType(DeclarationCode.fromParts([
        'Map<String, dynamic> to$to() => {\n',
        ...fields.where((e) => !e.ignoreTo).map((e) => '${_key(e.key, e.customKey)}: ${_jsonValue(e, methods)},\n'),
        '};',
      ]));
    }
  }

  Iterable _buildParse(MacroField field, List<MacroMethod> methods) {
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

  Iterable _parseObject(MacroField field, String key) {
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

  String _jsonValue(MacroField field, List<MacroMethod> methods) {
    final convert = field.toConverter;

    if (convert != null) {
      final method = methods.find<MacroMethod>((value) => value.name == convert);

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
*/