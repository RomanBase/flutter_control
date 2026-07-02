import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/// The single barrel that re-exports every flutter_control widget.
///
/// Because the framework uses `part` files behind one library, wrapping in ANY
/// control widget only ever needs this one import.
final Uri _controlBarrelUri = Uri(
  scheme: 'package',
  path: 'flutter_control/control.dart',
);

/// Priority for the "Wrap with …" assists in the lightbulb list. Mirrors the
/// value riverpod_lint uses so our assists sit alongside the built-in ones.
const int wrapPriority = 30;

/// Returns `true` if [type] is a Flutter `Widget` (or a subtype).
///
/// Walks the type's supertypes looking for a class named `Widget` declared in a
/// `package:flutter/…` library. Avoids pulling in a `TypeChecker` dependency for
/// a single check.
bool isFlutterWidget(DartType? type) {
  if (type is! InterfaceType) return false;

  bool isWidgetElement(InterfaceType t) {
    final element = t.element;
    if (element.name != 'Widget') return false;
    final uri = element.library.uri;
    return uri.scheme == 'package' && uri.pathSegments.first == 'flutter';
  }

  if (isWidgetElement(type)) return true;
  return type.allSupertypes.any(isWidgetElement);
}

/// Resolves the widget-creation expression the cursor is on.
///
/// `this.node` is the most-deeply-nested AST node covering the cursor, which for
/// a widget is usually the constructor name (`NamedType`/identifier), not the
/// [InstanceCreationExpression] itself. Walk up to the nearest enclosing
/// creation expression so the assist fires whether the cursor is on the type
/// name, inside the argument list, or on the whole expression.
InstanceCreationExpression? _targetWidget(AstNode? node) {
  for (var current = node; current != null; current = current.parent) {
    if (current is InstanceCreationExpression) return current;
    // Don't escape the enclosing statement/argument — stop at obvious barriers
    // so we wrap the widget under the cursor, not some far-out ancestor.
    if (current is Statement || current is FunctionBody) break;
  }
  return null;
}

/// Imports the flutter_control barrel into the edited file and returns the
/// identifier to use for [name] — prefixed (`fc.ControlBuilder`) if the existing
/// import uses a prefix, bare otherwise.
String importControlWidget(DartFileEditBuilder builder, String name) {
  final import = builder.importLibraryElement(_controlBarrelUri);
  final prefix = import.prefix;
  return prefix != null ? '$prefix.$name' : name;
}

/// Wraps the widget expression under the cursor in `ControlBuilder`.
///
/// Before: `Text('x')`
/// After:  `ControlBuilder(control: control, builder: (context, value) { return Text('x'); })`
///
/// The `control` argument is a placeholder the developer must replace.
class WrapWithControlBuilder extends ResolvedCorrectionProducer {
  WrapWithControlBuilder({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => const AssistKind(
    'wrap_with_control_builder',
    wrapPriority,
    'Wrap with ControlBuilder',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = _targetWidget(this.node);
    if (node == null) return;

    final createdType = node.constructorName.type.type;
    if (!isFlutterWidget(createdType)) return;

    await builder.addDartFileEdit(file, (builder) {
      final controlBuilder = importControlWidget(builder, 'ControlBuilder');
      builder.addSimpleInsertion(
        node.offset,
        '$controlBuilder(control: control, builder: (context, value) { return ',
      );
      builder.addSimpleInsertion(node.end, '; },)');
    });
  }
}
