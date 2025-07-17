import 'dart:async';

import 'package:macros/macros.dart';

//TODO: https://github.com/dart-lang/language/blob/main/working/macros/example/lib/auto_dispose.dart
macro class DisposeMacro implements ClassDefinitionMacro {
  const DisposeMacro();

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final disposeMethod = (await builder.methodsOf(clazz)).firstWhere((method) => method.identifier.name == 'dispose');
    final disposeBuilder = await builder.buildMethod(disposeMethod.identifier);

    disposeBuilder.augment(FunctionBodyCode.fromParts([
      '{\n',
      'printDebug(\'augment dispose\');\n',
      '}',
    ]));
  }

}