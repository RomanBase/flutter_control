import 'dart:async';

import 'package:macros/macros.dart';
import 'package:control_core/core.dart';

import '../macros.dart';

///https://api.dart.dev/stable/3.5.3/dart-core/dart-core-library.html
///just few common types
///this is shitty solution, but we don't have access to private _macros library to check functionality of IdentifierImpl and other classes where prefixes are generated,
///also TypePhaseIntrospector.resolveIdentifier is deprecated
const _dart_core = [
  'void',
  'dynamic',
  'Object',
  'String',
  'List',
  'Map',
  'Set',
  'Iterable',
  'int',
  'double',
  'num',
  'bool',
  'Duration',
  'DateTime',
  'Uri',
  'Function',
  'Future',
  'Stream',
  'Sink',
  'Type',
  'RegExp',
];

class MacroCore {
  const MacroCore._();

  static Identifier? knownIdentifier(Identifier identifier) {
    if (_dart_core.contains(identifier.name)) {
      return null;
    }

    return identifier;
  }
}

class MacroField {
  final FieldDeclaration declaration;

  ConstructorMetadataAnnotation? annotation;

  Map<String, ExpressionCode> args = {};

  MacroField({
    required this.declaration,
  }) {
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

  static Future<List<MacroField>> getFields(TypeDeclaration declaration, MemberDeclarationBuilder builder) async {
    final items = (await builder.fieldsOf(declaration)).map((e) => MacroField(declaration: e)).toList();

    if (declaration is ClassDeclaration && declaration.superclass != null) {
      final superClass = await builder.typeDeclarationOf(declaration.superclass!.identifier);
      final superItems = await getFields(superClass, builder);
      return [...items, ...superItems];
    }

    return items;
  }

  static Future<List<MacroField>> getFieldsOf(Identifier identifier, MemberDeclarationBuilder builder) async => getFields(await builder.typeDeclarationOf(identifier), builder);

  NamedTypeAnnotation get obj => declaration.type as NamedTypeAnnotation;

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

  String get fullType => obj.code.parts.map((e) => _codePart(e)).join('');

  String _codePart(Object part) {
    if (part is String) {
      return part;
    }

    if (part is Identifier) {
      return part.name;
    }

    if (part is NamedTypeAnnotationCode) {
      return part.name.name;
    }

    return part.toString();
  }

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

  bool isBasic() {
    return false;
  }

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

  Iterable<Object> getCodeParts({bool nullable = true}) {
    final output = <Object>[];

    for (var part in obj.code.parts) {
      if (part is String) {
        output.add(part);
        continue;
      }

      if (part is NamedTypeAnnotationCode) {
        part = part.name;
      }

      if (part is Identifier) {
        final identifier = MacroCore.knownIdentifier(part);

        if (identifier != null) {
          output.add(identifier);
        } else {
          output.add(part.name);
        }

        continue;
      }

      output.add(part.toString());
    }

    if (!nullable && output.last == '?') {
      output.removeLast();
    }

    return output;
  }
}

class MacroMethod {
  final MethodDeclaration declaration;

  MacroMethod({required this.declaration});

  static Future<List<MacroMethod>> getMethods(TypeDeclaration declaration, MemberDeclarationBuilder builder) async {
    final items = (await builder.methodsOf(declaration)).map((e) => MacroMethod(declaration: e)).toList();

    if (declaration is ClassDeclaration && declaration.superclass != null) {
      final superClass = await builder.typeDeclarationOf(declaration.superclass!.identifier);
      final superItems = await getMethods(superClass, builder);
      return [...items, ...superItems];
    }

    return items;
  }

  String get name => declaration.identifier.name;

  bool get hasParams => declaration.positionalParameters.isNotEmpty;
}
