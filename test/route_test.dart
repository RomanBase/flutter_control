import 'package:flutter_control/control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mask', () {
    test('init', () {
      final root = RouteMask.root;
      final empty = RouteMask.empty;
      final path = RouteMask.of('/path/to/page');
      final path2 = RouteMask.of('./path/to/page');
      final path3 = RouteMask.of('path/to/page/');
      final path4 = RouteMask.of('//X/path/to/page/');
      final path5 = RouteMask.of('X://X/path/to/page/');
      final path6 = RouteMask.of('X:/path/to/page/');
      final args = RouteMask.of('/path/to/page?arg=1');

      expect(root.path, equals('/'));
      expect(root.isEmpty, isFalse);

      expect(empty.path, equals('/'));
      expect(empty.isEmpty, isTrue);

      expect(path.path, equals('/path/to/page'));
      expect(path.isNotEmpty, isTrue);

      expect(path2.path, equals('/path/to/page'));
      expect(path3.path, equals('/path/to/page'));
      expect(path4.path, equals('/path/to/page'));
      expect(path5.path, equals('/path/to/page'));
      expect(path6.path, equals('/path/to/page'));

      expect(args.path, equals('/path/to/page'));
      expect(args.isNotEmpty, isTrue);
    });

    test('segment', () {
      final root = RouteMask.root;
      final empty = RouteMask.empty;
      final path = RouteMask.of('/path/to/page');
      final route = RouteMask.of('/path/{0}/page/{1}');

      expect(root.segmentCount, equals(1));
      expect(empty.segmentCount, equals(0));
      expect(path.segmentCount, equals(3));
      expect(route.segmentCount, equals(4));
      expect(route.args, equals(['{0}', '{1}']));
    });

    test('args', () {
      final path = RouteMask.of('/path/to/page');
      final route = RouteMask.of('/path/{0}/page/{1}');

      final none = path.format(null);
      final noArg = path.format('none');
      final oneArg = route.format('first');

      final listSmaller = route.format(['first']);
      final listExact = route.format(['first', 'second']);
      final listLarger = route.format(['first', 'second', 'third']);

      final mapSmaller = route.format({0: 'zero', '0': 'first'});
      final mapExact = route.format({'0': 'first', '1': 'second'});
      final mapLarger = route.format({0: 'first', 1: 'second', 2: 'third'});

      expect(none, equals('/path/to/page'));
      expect(noArg, equals('/path/to/page'));
      expect(oneArg, equals('/path/first/page/{1}'));

      expect(listSmaller, equals('/path/first/page/{1}'));
      expect(listExact, equals('/path/first/page/second'));
      expect(listLarger, equals('/path/first/page/second'));

      expect(mapSmaller, equals('/path/first/page/{1}'));
      expect(mapExact, equals('/path/first/page/second'));
      expect(mapLarger, equals('/path/first/page/second'));
    });

    test('matching', () {
      final path = RouteMask.of('/path/to/page');
      final route = RouteMask.of('/path/{0}/page/{1}');

      final exactMatch = path.match(RouteMask.of('/path/to/page'));
      final invalidMatch = path.match(RouteMask.of('/{0}/{1}/{2}'));

      final smallerArg = route.match(RouteMask.of('/path'));
      final smallerArg2 = route.match(RouteMask.of('/path/first/page'));
      final exactArg = route.match(RouteMask.of('/path/first/page/second'));
      final largerArg = route.match(RouteMask.of('/path/to/page/second/{0}'));

      expect(exactMatch, isTrue);
      expect(invalidMatch, isFalse);

      expect(smallerArg, isFalse);
      expect(smallerArg2, isFalse);
      expect(exactArg, isTrue);
      expect(largerArg, isFalse);
    });
  });
}
