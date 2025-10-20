import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:control_annotations/annotations.dart';
import 'package:recase/recase.dart';

class ParseGenerator extends Generator {
  final _parseEntityChecker = TypeChecker.fromRuntime(ParseEntity);

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final result = StringBuffer();

    final elements = library.annotatedWith(_parseEntityChecker).toList();

    if (elements.isEmpty) {
      return null;
    }

    for (final element in elements) {
      final generated = _generateForParseEntity(element.element, element.annotation);
      result.writeln(generated);
    }

    return result.toString();
  }

  String _generateForParseEntity(Element element, ConstantReader annotation) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@ParseEntity` can only be used on classes.',
        element: element,
      );
    }

    final className = element.name;
    final fromMethod = annotation.read('from').stringValue;
    final toMethod = annotation.read('to').stringValue;
    final keyType = annotation.read('keyType').stringValue;
    final copyWith = annotation.read('copyWith').boolValue;
    final copyWithData = annotation.read('copyWithData').boolValue;
    final bool storeModel = true;

    final allFields = _collectFields(element);
    final constructorParams = element.unnamedConstructor?.parameters ?? [];
    final constructorFieldNames = constructorParams.map((p) => p.name).toSet();
    final constructorFields = allFields.where((f) => constructorFieldNames.contains(f.name)).toList();

    final buffer = StringBuffer();

    buffer.writeln('$className $fromMethod(Map<String, dynamic> data) => $className(');
    for (final field in constructorFields) {
      if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

      final fieldAnnotation = _getParseValueAnnotation(field);
      if (_shouldIgnore(fieldAnnotation, ParseIgnore.from)) continue;

      final fromConverter = fieldAnnotation?.peek('fromConverter')?.revive().source.fragment;
      if (fromConverter != null && fromConverter.isNotEmpty) {
        buffer.writeln('  ${field.name}: $fromConverter(data),');
        continue;
      }

      final raw = fieldAnnotation?.peek('raw')?.boolValue ?? false;
      final key = _getKey(field, keyType, fieldAnnotation);

      if (raw) {
        buffer.writeln('  ${field.name}: data[\'$key\'],');
        continue;
      }

      final parser = _getParser(field, key, fieldAnnotation);
      buffer.writeln('  ${field.name}: $parser,');
    }
    buffer.writeln(');\n');

    // FROM FACTORY
    buffer.writeln('extension ${className}Factory on $className {\n');

    // TO JSON
    buffer.writeln('  Map<String, dynamic> $toMethod() => {');
    for (final field in allFields) {
      if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

      final fieldAnnotation = _getParseValueAnnotation(field);
      if (_shouldIgnore(fieldAnnotation, ParseIgnore.to)) continue;

      final toConverter = fieldAnnotation?.peek('toConverter')?.revive().source.fragment;
      final key = _getKey(field, keyType, fieldAnnotation);
      if (toConverter != null && toConverter.isNotEmpty) {
        buffer.writeln('    \'$key\': $toConverter(${field.name}),');
        continue;
      }

      final raw = fieldAnnotation?.peek('raw')?.boolValue ?? false;
      final serializer = raw ? field.name : _getSerializer(field);

      buffer.writeln('    \'$key\': $serializer,');
    }
    buffer.writeln('  };\n');

    // COPY WITH
    if (copyWith) {
      buffer.writeln('  $className copyWith({');
      for (final field in constructorFields) {
        if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

        buffer.writeln('    ${field.type}${field.type.isNullable ? '' : '?'} ${field.name},');
      }

      buffer.write('}) => $className(');

      for (final field in constructorFields) {
        if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

        buffer.writeln('    ${field.name}: ${field.name} ?? this.${field.name},');
      }

      buffer.writeln('  );\n');
    }

    // COPY WITH DATA
    if (copyWithData) {
      buffer.writeln('  $className copyWithData(Map<String, dynamic> data) => $className(');
      for (final field in constructorFields) {
        if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

        final fieldAnnotation = _getParseValueAnnotation(field);
        if (_shouldIgnore(fieldAnnotation, ParseIgnore.from)) continue;

        final contains = 'data.containsKey(\'${_getKey(field, keyType, fieldAnnotation)}\') ?';

        final fromConverter = fieldAnnotation?.peek('fromConverter')?.revive().source.fragment;
        if (fromConverter != null && fromConverter.isNotEmpty) {
          buffer.writeln('    ${field.name}: $contains $fromConverter(data) : ${field.name},');
          continue;
        }

        final raw = fieldAnnotation?.peek('raw')?.boolValue ?? false;
        final key = _getKey(field, keyType, fieldAnnotation);

        if (raw || field.type is DynamicType) {
          buffer.writeln('    ${field.name}: data[\'$key\'] ?? ${field.name},');
          continue;
        }

        final parser = _getParser(field, key, fieldAnnotation, true);
        buffer.writeln('    ${field.name}: $contains $parser : ${field.name},');
      }
      buffer.writeln('  );\n');
    }

    buffer.writeln('}');

    // STORE MODEL
    if (storeModel) {
      buffer.writeln('''
      mixin ${className}Store {
        late $className ${className.camelCase};
      
        @protected
        void onUpdate${className}(Map<String, dynamic> data);
      
        void updateData${className}(Map<String, dynamic> data) {
          ${className.camelCase} = ${className.camelCase}.copyWithData(data);
      
          if (this is ObservableNotifier) {
            (this as ObservableNotifier).notify();
          }
        }
      ''');

      buffer.writeln('void update$className({');
      for (final field in constructorFields) {
        if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

        buffer.writeln('    ${field.type}${field.type.isNullable ? '' : '?'} ${field.name},');
      }
      buffer.write('}){');
      buffer.writeln('final data = {');

      for (final field in constructorFields) {
        if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

        final fieldAnnotation = _getParseValueAnnotation(field);
        if (_shouldIgnore(fieldAnnotation, ParseIgnore.to)) continue;

        final toConverter = fieldAnnotation?.peek('toConverter')?.revive().source.fragment;
        final key = _getKey(field, keyType, fieldAnnotation);
        if (toConverter != null && toConverter.isNotEmpty) {
          buffer.writeln('    if(${field.name} != null) \'$key\': $toConverter(${field.name}),');
          continue;
        }

        final raw = fieldAnnotation?.peek('raw')?.boolValue ?? false;
        final serializer = raw ? field.name : _getSerializer(field, notNull: true);

        buffer.writeln('    if(${field.name} != null) \'$key\': $serializer,');
      }
      buffer.writeln('  };\n');

      buffer.writeln('  ${className.camelCase} = ${className.camelCase}.copyWith(');
      for (final field in constructorFields) {
        if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer) || field.isSynthetic) continue;

        buffer.writeln('    ${field.name}: ${field.name},');
      }
      buffer.writeln('  );\n');

      buffer.writeln('    onUpdate${className}(data);\n');
      buffer.writeln('''
          if (this is ObservableNotifier) {
            (this as ObservableNotifier).notify();
          }
      ''');

      buffer.writeln('    }');
      buffer.writeln('}');
    }

    return buffer.toString();
  }

  List<FieldElement> _collectFields(ClassElement element) {
    final fields = List<FieldElement>.from(element.fields);
    final supertype = element.supertype;

    if (supertype != null && supertype.element.name != 'Object') {
      final superElement = supertype.element;
      if (superElement is ClassElement) {
        fields.insertAll(0, _collectFields(superElement));
      }
    }

    return fields;
  }

  String _getParserPrimitive(DartType type, String value) {
    if (type.isDartCoreString) return 'Parse.string($value)';
    if (type.isDartCoreInt) return 'Parser.toInteger($value)';
    if (type.isDartCoreDouble) return 'Parser.toDouble($value)';
    if (type.isDartCoreBool) return 'Parser.toBool$value)';
    if (type.isEnum) return 'Parser.toEnum($value, ${type.element?.name}.values)';

    return value;
  }

  String _getParser(FieldElement field, String key, ConstantReader? annotation, [bool ignoreDefault = false]) {
    final type = field.type;
    final defaultValueStr = ignoreDefault ? '' : _getDefaultValue(annotation, type);
    final nullable = ignoreDefault ? false : type.isNullable;
    final parser = nullable ? 'ParseN' : 'Parse';

    if (type.isDartCoreString) return '$parser.string(data[\'$key\']$defaultValueStr)';
    if (type.isDartCoreInt) return '$parser.toInteger(data[\'$key\']$defaultValueStr)';
    if (type.isDartCoreDouble) return '$parser.toDouble(data[\'$key\']$defaultValueStr)';
    if (type.isDartCoreBool) return '$parser.toBool(data[\'$key\']$defaultValueStr)';
    if (type.element?.name == 'DateTime') return 'Parse.date(data[\'$key\']$defaultValueStr)${type.isNullable ? '' : '!'}';
    if (type.isEnum) return '$parser.toEnum(data[\'$key\'], ${type.element?.name}.values$defaultValueStr)';

    if (type is InterfaceType && type.isDartCoreList) {
      final argType = type.typeArguments.first;
      final converter = annotation?.peek('converter')?.revive().source.fragment;

      final itemConverter = (converter != null && converter.isNotEmpty) ? converter : _getConverter(argType, 'item');
      return 'Parse.toList(data[\'$key\'], converter: $itemConverter)';
    }

    if (type is InterfaceType && type.isDartCoreMap) {
      final keyType = type.typeArguments[0];
      final valueType = type.typeArguments[1];

      final keyConverter = annotation?.peek('keyConverter')?.revive().source.fragment;
      final converter = annotation?.peek('converter')?.revive().source.fragment;
      final entryConverter = annotation?.peek('entryConverter')?.revive().source.fragment;

      final keyFunction = (keyConverter != null && keyConverter.isNotEmpty) ? keyConverter : _getEntryConverter(keyType, valueType, 'key', 'value', true);
      final convertFunction = (converter != null && converter.isNotEmpty) ? converter : _getConverter(valueType, 'value');
      final convertEntryFunction = (entryConverter != null && entryConverter.isNotEmpty) ? entryConverter : null;

      final converterFunction = convertEntryFunction == null ? 'converter: $convertFunction' : 'entryConverter: $convertEntryFunction';

      return 'Parse.toKeyMap(data[\'$key\'], ${keyFunction}, $converterFunction)';
    }

    final typeElement = type.element;
    if (typeElement is ClassElement) {
      String classParser = '${typeElement.name}.fromJson(data[\'$key\'])';

      final entityAnnotation = _parseEntityChecker.firstAnnotationOf(typeElement);
      if (entityAnnotation != null) {
        final fromMethod = ConstantReader(entityAnnotation).peek('from')?.stringValue ?? 'Json';
        classParser = '${typeElement.name}.from$fromMethod(data[\'$key\'])';
      }

      return '${nullable ? 'data.containsKey(\'$key\') ? $classParser : null' : '$classParser'}';
    }

    return 'data[\'$key\']${ignoreDefault ? '' : _getDefaultValue(annotation, type, true)}';
  }

  String _getConverter(DartType type, String varName) {
    if (type.isPrimitive || type.element?.name == 'dynamic') return '($varName) => $varName';
    if (type.element?.name == 'DateTime') return '($varName) => Parse.date($varName)${type.isNullable ? '' : '!'}';
    if (type.isEnum) return '($varName) => Parse.toEnum($varName, ${type.element?.name}.values)';

    final typeElement = type.element;
    if (typeElement is ClassElement) {
      final entityAnnotation = _parseEntityChecker.firstAnnotationOf(typeElement);
      if (entityAnnotation != null) {
        final fromMethod = ConstantReader(entityAnnotation).peek('from')?.stringValue ?? 'Json';
        return '($varName) => ${typeElement.name}${type.isNullable ? '?' : ''}.from$fromMethod($varName)';
      }
    }

    return '($varName) => ${type.element?.name}${type.isNullable ? '?' : ''}.fromJson($varName)';
  }

  String _getEntryConverter(DartType keyType, DartType varType, String keyName, String varName, [bool useKey = false]) {
    final valueName = useKey ? keyName : varName;
    final valueType = useKey ? keyType : varType;

    if (valueType.isPrimitive || valueType.element?.name == 'dynamic') return '($keyName, $varName) => ${_getParserPrimitive(valueType, valueName)}';
    if (valueType.element?.name == 'DateTime') return '($keyName, $varName) => Parse.date($valueName)${valueType.isNullable ? '' : '!'}';
    if (valueType.isEnum) return '($keyName, $varName) => Parse.toEnum($valueName, ${valueType.element?.name}.values)';

    final typeElement = valueType.element;
    if (typeElement is ClassElement) {
      final entityAnnotation = _parseEntityChecker.firstAnnotationOf(typeElement);
      if (entityAnnotation != null) {
        final fromMethod = ConstantReader(entityAnnotation).peek('from')?.stringValue ?? 'Json';
        return '($keyName, $varName) => ${typeElement.name}${valueType.isNullable ? '?' : ''}.from$fromMethod($valueName)';
      }
    }

    return '($keyName, $varName) => ${valueType.element?.name}${valueType.isNullable ? '?' : ''}.fromJson($valueName)';
  }

  String _getSerializer(FieldElement field, {bool notNull = false}) {
    final type = field.type;
    final nullable = notNull ? false : type.isNullable;
    final name = field.name;

    if (type.isPrimitive) return name;
    if (type.element?.name == 'DateTime') return '$name${nullable ? '?' : ''}.toIso8601String()';
    if (type.isEnum) return '$name${nullable ? '?' : ''}.name';

    if (type is InterfaceType && type.isDartCoreList) {
      final argType = type.typeArguments.first;
      final itemSerializer = _getSerializerForType(argType, 'e');
      if (itemSerializer == 'e') return name;
      return '$name${nullable ? '?' : ''}.map((e) => $itemSerializer).toList()';
    }

    if (type is InterfaceType && type.isDartCoreMap) {
      final valueType = type.typeArguments[1];
      final valueSerializer = _getSerializerForType(valueType, 'value');
      if (valueSerializer == 'value') return name;

      return '$name${nullable ? '?' : ''}.map((key, value) => MapEntry(key, $valueSerializer))';
    }

    final typeElement = type.element;
    if (typeElement is ClassElement) {
      String toMethod = 'Json';

      final entityAnnotation = _parseEntityChecker.firstAnnotationOf(typeElement);
      if (entityAnnotation != null) {
        toMethod = ConstantReader(entityAnnotation).peek('to')?.stringValue ?? 'Json';
      }

      return '$name${nullable ? '?' : ''}.to$toMethod()';
    }

    return '$name';
  }

  String _getSerializerForType(DartType type, String varName) {
    if (type.isPrimitive) return varName;
    if (type.element?.name == 'DateTime') return '$varName.toIso8601String()';
    if (type.isEnum) return '$varName.name';

    final typeElement = type.element;
    if (typeElement is ClassElement) {
      final entityAnnotation = _parseEntityChecker.firstAnnotationOf(typeElement);
      if (entityAnnotation != null) {
        final toMethod = ConstantReader(entityAnnotation).peek('to')?.stringValue ?? 'Json';
        return '$varName${type.isNullable ? '?' : ''}.to$toMethod()';
      }
    }

    return '$varName';
  }

  ConstantReader? _getParseValueAnnotation(FieldElement field) {
    final checker = TypeChecker.fromRuntime(ParseValue);
    final annotation = checker.firstAnnotationOf(field);
    return annotation != null ? ConstantReader(annotation) : null;
  }

  bool _shouldIgnore(ConstantReader? annotation, ParseIgnore ignore) {
    if (annotation == null) return false;
    final ignoreValue = annotation.peek('ignore')?.objectValue.getField('index')?.toIntValue();
    return ignoreValue == ignore.index || ignoreValue == ParseIgnore.both.index;
  }

  String _getKey(FieldElement field, String keyType, ConstantReader? annotation) {
    final customKey = annotation?.peek('key')?.stringValue;
    if (customKey != null && customKey.isNotEmpty) {
      return customKey;
    }

    switch (keyType) {
      case 'snake_case':
        return field.name.snakeCase;
      case 'camelCase':
        return field.name.camelCase;
      case 'PascalCase':
        return field.name.pascalCase;
      default:
        return field.name;
    }
  }

  String _getDefaultValue(ConstantReader? annotation, DartType type, [bool qq = false]) {
    final reader = annotation?.peek('defaultValue');

    if (reader == null || reader.isNull) {
      return '';
    }

    if (type.isEnum) {
      final revived = reader.revive();
      return qq ? ' ?? ${revived.source.fragment}.${revived.accessor}' : ', defaultValue: ${revived.source.fragment}.${revived.accessor}';
    }

    final literal = reader.literalValue;
    if (literal is String) {
      final escaped = literal.replaceAll("'", "\\'").replaceAll('\$', '\\\$');
      return qq ? ' ?? $escaped' : ", defaultValue: '$escaped'";
    }

    return qq ? ' ?? $literal' : ', defaultValue: $literal';
  }
}

extension on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question || this is DynamicType;

  bool get isPrimitive => isDartCoreString || isDartCoreInt || isDartCoreDouble || isDartCoreBool || isDartCoreObject;

  bool get isEnum => element is EnumElement;
}
