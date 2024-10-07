import 'dart:async';

import 'package:macros/macros.dart';
import 'package:control_core/core.dart';

import 'declarations.dart';

macro class CopyEntity implements ConstructorDeclarationsMacro {
  final String name;
  final bool private;

  //Only named params are supported right now
  const CopyEntity({
    this.name = 'copyWith',
    this.private = false,
  });

  @override
  FutureOr<void> buildDeclarationsForConstructor(ConstructorDeclaration constructor, MemberDeclarationBuilder builder) async {
    final clazz = constructor.definingType.name;
    final fields = Parse.toKeyMap<String, MacroField>(await MacroField.getFieldsOf(constructor.definingType, builder), (key, value) => value.name);
    final params = constructor.namedParameters;

    fields.forEach((key, value) {
      builder.declareInLibrary(DeclarationCode.fromString('//${value.fullType} - ${(value.declaration.type as NamedTypeAnnotation).code.parts}'));
    });

    builder.declareInType(DeclarationCode.fromParts([
      '\n',
      '$clazz ${private ? '_' : ''}$name({\n',
      for(final param in params)
        ...[...fields[param.identifier.name]!.getCodeParts(nullable: false), '? ${param.identifier.name},\n'],
      '}) => $clazz(\n',
      ...params.map((e) => '${e.identifier.name}: ${e.identifier.name} ?? this.${e.identifier.name},\n'),
      ');',
    ]));
  }


}
