import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

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
    return uri.scheme == 'package' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'flutter';
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
@visibleForTesting
InstanceCreationExpression? targetWidget(AstNode? node) {
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

/// Describes one "Wrap with …" assist. The transform is identical across the
/// flutter_control builders — only these strings vary — so the producers are
/// thin wrappers around a shared [wrapWith] instead of an inheritance hierarchy.
class WrapAssistSpec {
  const WrapAssistSpec({
    required this.kindId,
    required this.widgetName,
    required this.seedArgs,
    required this.builderParams,
  });

  /// Stable assist id, e.g. `wrap_with_control_builder`.
  final String kindId;

  /// The flutter_control widget to wrap into, e.g. `ControlBuilder`.
  final String widgetName;

  /// The required argument(s) seeded before `builder:`, e.g.
  /// `control: control,` or `controls: [control],`. `control` is a placeholder
  /// the developer replaces with a real observable.
  final String seedArgs;

  /// The `builder:` callback parameter list, e.g. `context, value`.
  final String builderParams;

  AssistKind get assistKind =>
      AssistKind(kindId, wrapPriority, 'Wrap with $widgetName');

  /// Text inserted at the widget's start offset. [widgetRef] is the (possibly
  /// import-prefixed) name to emit — bare [widgetName] in tests.
  String opening([String? widgetRef]) =>
      '${widgetRef ?? widgetName}($seedArgs builder: ($builderParams) { return ';

  /// Text inserted at the widget's end offset.
  String get closing => '; },)';
}

/// Shared transform: wrap the widget under the cursor into [spec]'s builder.
///
/// Before: `Text('x')`
/// After:  `ControlBuilder(control: control, builder: (context, value) { return Text('x'); })`
Future<void> wrapWith(
  WrapAssistSpec spec,
  AstNode? cursorNode,
  String file,
  ChangeBuilder builder,
) async {
  final node = targetWidget(cursorNode);
  if (node == null) return;

  final createdType = node.constructorName.type.type;
  if (!isFlutterWidget(createdType)) return;

  await builder.addDartFileEdit(file, (builder) {
    final widget = importControlWidget(builder, spec.widgetName);
    builder.addSimpleInsertion(node.offset, spec.opening(widget));
    builder.addSimpleInsertion(node.end, spec.closing);
  });
}

/// Wrap in `ControlBuilder(control: …, builder: (context, value) { … })`.
class WrapWithControlBuilder extends ResolvedCorrectionProducer {
  WrapWithControlBuilder({required super.context});

  static const _spec = WrapAssistSpec(
    kindId: 'wrap_with_control_builder',
    widgetName: 'ControlBuilder',
    seedArgs: 'control: control,',
    builderParams: 'context, value',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _spec.assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) =>
      wrapWith(_spec, node, file, builder);
}

/// Wrap in `ControlBuilderGroup(controls: [control], builder: (context, values) { … })`.
class WrapWithControlBuilderGroup extends ResolvedCorrectionProducer {
  WrapWithControlBuilderGroup({required super.context});

  static const _spec = WrapAssistSpec(
    kindId: 'wrap_with_control_builder_group',
    widgetName: 'ControlBuilderGroup',
    seedArgs: 'controls: [control],',
    builderParams: 'context, values',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _spec.assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) =>
      wrapWith(_spec, node, file, builder);
}

/// Wrap in `FieldBuilder(control: …, builder: (context, value) { … })`.
class WrapWithFieldBuilder extends ResolvedCorrectionProducer {
  WrapWithFieldBuilder({required super.context});

  static const _spec = WrapAssistSpec(
    kindId: 'wrap_with_field_builder',
    widgetName: 'FieldBuilder',
    seedArgs: 'control: control,',
    builderParams: 'context, value',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _spec.assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) =>
      wrapWith(_spec, node, file, builder);
}

/// Wrap in `ListBuilder(control: …, builder: (context, list) { … })`.
class WrapWithListBuilder extends ResolvedCorrectionProducer {
  WrapWithListBuilder({required super.context});

  static const _spec = WrapAssistSpec(
    kindId: 'wrap_with_list_builder',
    widgetName: 'ListBuilder',
    seedArgs: 'control: control,',
    builderParams: 'context, list',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _spec.assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) =>
      wrapWith(_spec, node, file, builder);
}
