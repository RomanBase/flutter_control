import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:control_annotations/annotations.dart';
import 'package:recase/recase.dart';

class ParserGenerator extends Generator {
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
    final listMethod = annotation.read('list').stringValue;
    final keyType = annotation.read('keyType').stringValue;

    final buffer = StringBuffer();

    if (listMethod.isNotEmpty) {
      buffer.writeln('extension \$${className}ListExtension on List<$className> {');
      buffer.writeln('  static List<$className> from$listMethod(dynamic data) => Parse.toList(data, converter: (item) => $className.from$fromMethod(item));');
      buffer.writeln('}');
    }

    // FROM FACTORY
    buffer.writeln('extension \$${className}Factory on $className {');
    buffer.writeln('  static $className from$fromMethod(Map<String, dynamic> data) => $className(');
    for (final field in element.fields) {
      if (field.isStatic || field.isConst || (field.isFinal && field.hasInitializer)) continue;

      final fieldAnnotation = _getParseValueAnnotation(field);
      if (_shouldIgnore(fieldAnnotation, ParseIgnore.from)) continue;

      final fromConverter = fieldAnnotation?.peek('fromConverter')?.revive().source.fragment;
      if (fromConverter != null && fromConverter.isNotEmpty) {
        buffer.writeln('    ${field.name}: $fromConverter(data),');
        continue;
      }

      final raw = fieldAnnotation?.peek('raw')?.boolValue ?? false;
      final key = _getKey(field, keyType, fieldAnnotation);

      if (raw) {
        buffer.writeln('    ${field.name}: data[\'$key\'],');
        continue;
      }

      final parser = _getParser(field, key, fieldAnnotation);
      buffer.writeln('    ${field.name}: $parser,');
    }
    buffer.writeln('  );');
    buffer.writeln('');

    // TOJSON
    buffer.writeln('  Map<String, dynamic> to$toMethod() => {');
    for (final field in element.fields) {
      if (field.isStatic || field.isConst) continue;

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
    buffer.writeln('  };');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getParser(FieldElement field, String key, ConstantReader? annotation) {
    final type = field.type;
    final defaultValueStr = _getDefaultValue(annotation, type);
    final nullable = type.isNullable;
    final parser = nullable ? 'ParseN' : 'Parse';
    final converter = annotation?.peek('converter')?.revive().source.fragment;

    if (type.isDartCoreString) return '$parser.string(data[\'$key\']$defaultValueStr)';
    if (type.isDartCoreInt) return '$parser.toInteger(data[\'$key\']$defaultValueStr)';
    if (type.isDartCoreDouble) return '$parser.toDouble(data[\'$key\']$defaultValueStr)';
    if (type.isDartCoreBool) return '$parser.toBool(data[\'$key\']$defaultValueStr)';
    if (type.element?.name == 'DateTime') return 'Parse.date(data[\'$key\']$defaultValueStr)${type.isNullable ? '' : '!'}';
    if (type.isEnum) return '$parser.toEnum(data[\'$key\'], ${type.element?.name}.values$defaultValueStr)';
    if (type.element is DynamicType) return 'data[\'$key\']';

    if (type is InterfaceType && type.isDartCoreList) {
      final argType = type.typeArguments.first;
      final itemConverter = (converter != null && converter.isNotEmpty) ? converter : _getConverter(argType, 'item');
      return '$parser.toList(data[\'$key\'], converter: $itemConverter$defaultValueStr)';
    }

    if (type is InterfaceType && type.isDartCoreMap) {
      final valueType = type.typeArguments[1];
      final valueConverter = (converter != null && converter.isNotEmpty) ? converter : _getConverter(valueType, 'value');
      return '$parser.toMap(data[\'$key\'], converter: $valueConverter$defaultValueStr)';
    }

    final typeElement = type.element;
    if (typeElement is ClassElement) {
      final entityAnnotation = _parseEntityChecker.firstAnnotationOf(typeElement);
      if (entityAnnotation != null) {
        final fromMethod = ConstantReader(entityAnnotation).peek('from')?.stringValue ?? 'Json';
        return '${typeElement.name}.from$fromMethod(data)';
      }
    }

    return 'data[\'$key\']$defaultValueStr';
  }

  String _getConverter(DartType type, String varName) {
    if (type.isPrimitive || type.element?.name == 'dynamic') return '($varName) => $varName';
    if (type.element?.name == 'DateTime') return '($varName) => Parse.date($varName)';
    if (type.isEnum) return '($varName) => Parse.toEnum($varName, values: ${type.element?.name}.values)';

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

  String _getSerializer(FieldElement field) {
    final type = field.type;
    final nullable = type.isNullable;
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
      final entityAnnotation = _parseEntityChecker.firstAnnotationOf(typeElement);
      if (entityAnnotation != null) {
        final toMethod = ConstantReader(entityAnnotation).peek('to')?.stringValue ?? 'Json';
        return '$name${nullable ? '?' : ''}.to$toMethod()';
      }
    }

    return '$name${nullable ? '?' : ''}.toJson()';
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

    return '$varName${type.isNullable ? '?' : ''}.toJson()';
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

  String _getDefaultValue(ConstantReader? annotation, DartType type) {
    final reader = annotation?.peek('defaultValue');

    if (reader == null || reader.isNull) {
      return '';
    }

    if (type.isEnum) {
      final revived = reader.revive();
      return ', defaultValue: ${revived.source.fragment}.${revived.accessor}';
    }

    final literal = reader.literalValue;
    if (literal is String) {
      final escaped = literal.replaceAll("'", "\\'").replaceAll('\$', '\\\$');
      return ", defaultValue: '$escaped'";
    }

    return ', defaultValue: $literal';
  }
}

extension on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;

  bool get isPrimitive => isDartCoreString || isDartCoreInt || isDartCoreDouble || isDartCoreBool;

  bool get isEnum => element is EnumElement;
}
