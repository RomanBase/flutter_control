import 'dart:async';

import 'package:macros/macros.dart';
import 'package:control_core/core.dart';

class ParseValue<T> {
  final bool index;
  final String? key;
  final T? defaultValue;

  const ParseValue({
    this.index = false,
    this.key,
    this.defaultValue,
  });
}

class ParseIgnore {
  const ParseIgnore();
}

class ParseIgnoreFrom {
  const ParseIgnoreFrom();
}

class ParseIgnoreTo {
  const ParseIgnoreTo();
}

macro class ParseEntity implements ClassDeclarationsMacro {
  final bool from;
  final bool to;

  const ParseEntity({
    this.from = true,
    this.to = true,
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

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final fields = await _getFields(clazz, builder);

    builder.declareInLibrary(DeclarationCode.fromString('import \'package:control_core/core.dart\';'));
    builder.declareInLibrary(DeclarationCode.fromString(''));

    if (from) {
      builder.declareInType(DeclarationCode.fromParts([
        'factory ${clazz.identifier.name}.fromJson(Map<String, dynamic> data) => ${clazz.identifier.name}(\n',
        ...fields.where((e) => !e.ignoreFrom).map((e) => _buildParse(e)).reduce((a, b) => [...a, DeclarationCode.fromString(',\n'), ...b]),
        ');',
      ]));
    }

    if (to) {
      builder.declareInType(DeclarationCode.fromString(''));
      builder.declareInType(DeclarationCode.fromParts([
        'Map<String, dynamic> toJson() => {\n',
        ...fields.where((e) => !e.ignoreTo).map((e) => '\'${e.name}\': ${isPrimitive(e.type) ? e.name : '${e.name}${e.nullable ? '?' : ''}.toJson()'},\n'),
        '};',
      ]));
    }
  }

  Iterable _buildParse(_Field field) {
    if (field.type.startsWith('List')) {
      final arg = (field.obj.typeArguments.first as NamedTypeAnnotation).identifier.name.toLowerCase();
      return ['${field.name}: Parse.toList(data[${field.key}], converter: (data) => \'$arg\')'];
    } else if (field.type.startsWith('Map')) {
      return ['${field.name}: Parse.toKeyMap(data[${field.key}], (key, value) => \'\$key\', entryConverter: (key, data) => data)'];
    } else if (field.type.startsWith('DateTime')) {
      return ['${field.name}: Parse.date(data[${field.key}])${field.nullable ? '' : '!'}'];
    }

    return _parseObject(field);
  }

  Iterable _parseObject(_Field field) {
    if (isPrimitive(field.type)) {
      if (field.nullable) {
        return ['${field.name}: ParseN.${_parseFunction(field.type, field.key, field.defaultValue)}'];
      }

      return ['${field.name}: Parse.${_parseFunction(field.type, field.key, field.defaultValue)}'];
    }

    return ['${field.name}: ', field.obj.identifier, '.fromJson(data[${field.key}])'];
  }

  String _parseFunction(String type, dynamic key, [dynamic value]) =>
      switch(type.toLowerCase()) {
        'string' => 'string(data[$key]${_defaultValue(value)})',
        'int' => 'toInteger(data[$key]${_defaultValue(value)})',
        'double' => 'toDouble(data[$key]${_defaultValue(value)})',
        'number' => 'toDouble(data[$key]${_defaultValue(value)})',
        'bool' => 'toBool(data[$key]${_defaultValue(value)})',
        _ => 'data[$key]'
      };

  String _defaultValue(dynamic defaultValue) => defaultValue == null ? '' : ', defaultValue: $defaultValue';

  bool isPrimitive(String type) {
    return type == 'dynamic' || type == 'String' || type == 'int' || type == 'double' || type == 'number' || type == 'bool' || type == 'DateTime';
  }
}

class _Field {
  final FieldDeclaration declaration;
  late final NamedTypeAnnotation obj;

  ConstructorMetadataAnnotation? annotation;
  bool ignoreFrom = false;
  bool ignoreTo = false;

  _Field({
    required this.declaration,
  }) {
    obj = declaration.type as NamedTypeAnnotation;

    for (final ann in declaration.metadata) {
      if (ann is ConstructorMetadataAnnotation) {
        switch (ann.type.identifier.name) {
          case 'ParseValue':
            annotation = ann;
            break;
          case 'ParseIgnore':
            ignoreFrom = true;
            ignoreTo = true;
            break;
          case 'ParseIgnoreFrom':
            ignoreFrom = true;
            break;
          case 'ParseIgnoreTo':
            ignoreTo = true;
            break;
        }
      }
    }
  }

  String get name => declaration.identifier.name;

  String get type => obj.identifier.name;

  bool get nullable => obj.isNullable;

  bool get index => annotation?.namedArguments['index']?.parts.first == 'true';

  dynamic get key => annotation?.namedArguments['key']?.parts.first ?? '\'$name\'';

  dynamic get defaultValue => annotation?.namedArguments['defaultValue']?.parts.first;

}