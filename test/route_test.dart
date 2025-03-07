import 'package:flutter_control/control.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_widget.dart';

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

    test('params', () {
      final path = RouteMask.of('/path/to/page/detail');
      final route = RouteMask.of('/path/{0}/page/{1}');
      final pathS = RouteMask.of('/path/to/');

      final args1 = path.params(route);
      final args2 = route.params(path);
      final args3 = route.params(pathS);

      expect(args1, equals({'0': 'to', '1': 'detail'}));
      expect(args1, equals(args2));
      expect(args3, equals({'0': 'to'}));
    });

    test('query', () {
      final path = RouteMask.of('/path/to/page/detail?q=args');
      final route = RouteMask.of('/path/{0}/page/{1}');

      final args1 = path.params(route);
      final args2 = route.params(path);

      expect(args1, equals({'0': 'to', '1': 'detail', 'q': 'args'}));
      expect(args1, equals(args2));
    });

    /*test('restore', () {
      final path = RouteMask.of('/path/to/page/detail');
      final mask = RouteMask.of('/path/{0}/page/{1}');

      final store = RouteStore([
        ControlRoute.build<Container>(builder: (_) => Container(), mask: mask.path),
      ]);

      final route = store.routing.generate(
        MockBuildContext(),
        RouteSettings(
          name: path.path,
          arguments: {'arg': 'X'},
        ),
        active: true,
      );

      expect(route, isNotNull);
      expect(route?.settings.name, equals(path.path));
      expect(Parse.getArg(route?.settings.arguments, key: '0'), equals('to'));
      expect(Parse.getArg(route?.settings.arguments, key: 'arg'), equals('X'));
      expect(Parse.getArg<RouteMask>(route?.settings.arguments)?.path, equals(mask.path));
    });*/
  });
}
