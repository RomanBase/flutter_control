import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:control_lint/src/wrap_assist.dart';
import 'package:test/test.dart';

/// Parses [source] and returns the most deeply nested node whose range contains
/// [offset] — i.e. what the analysis server hands the assist as `this.node`.
///
/// Uses explicit `new` so the *unresolved* parser produces
/// [InstanceCreationExpression] (without `new`, an unresolved `Foo()` parses as
/// a `MethodInvocation` — a constructor call can't be distinguished from a
/// function call until resolution). The resolved analysis server always yields
/// [InstanceCreationExpression], so this faithfully exercises [targetWidget]'s
/// node walk.
AstNode _nodeAt(String source, int offset) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final finder = _NodeAtOffsetFinder(offset);
  unit.accept(finder);
  return finder.result!;
}

class _NodeAtOffsetFinder extends UnifyingAstVisitor<void> {
  _NodeAtOffsetFinder(this.offset);

  final int offset;
  AstNode? result;

  @override
  void visitNode(AstNode node) {
    if (node.offset <= offset && offset <= node.end) {
      // Deeper nodes are visited after their parents, so the last match wins.
      result = node;
      super.visitNode(node);
    }
  }
}

void main() {
  const source = '''
Widget build() {
  return new Center(child: new Text('hello'));
}
''';

  final centerNameOffset = source.indexOf('Center');
  final childArgOffset = source.indexOf('child:');
  final textOffset = source.indexOf('Text');

  group('targetWidget', () {
    test('cursor on the constructor name resolves the creation expression', () {
      // The case that regressed in the spike: `this.node` is the type name, not
      // the InstanceCreationExpression.
      final node = targetWidget(_nodeAt(source, centerNameOffset));
      expect(node, isA<InstanceCreationExpression>());
      expect(node!.toSource(), startsWith('new Center('));
    });

    test('cursor inside the argument list still resolves the widget', () {
      final node = targetWidget(_nodeAt(source, childArgOffset));
      expect(node, isA<InstanceCreationExpression>());
      expect(node!.toSource(), startsWith('new Center('));
    });

    test('cursor on a nested widget resolves the innermost widget', () {
      final node = targetWidget(_nodeAt(source, textOffset));
      expect(node, isA<InstanceCreationExpression>());
      expect(node!.toSource(), startsWith("new Text('hello')"));
    });

    test('cursor not on any widget resolves nothing', () {
      const plain = 'int answer = 42;';
      final node = targetWidget(_nodeAt(plain, plain.indexOf('42')));
      expect(node, isNull);
    });

    test('null node resolves nothing', () {
      expect(targetWidget(null), isNull);
    });
  });

  group('isFlutterWidget guards', () {
    test('null type is not a widget', () {
      expect(isFlutterWidget(null), isFalse);
    });

    // A non-InterfaceType (e.g. a function type) reaches the early return.
    // Verified indirectly: null and non-widget inputs both yield false without
    // throwing. Full positive coverage needs a resolved SDK (see test/README).
  });
}
