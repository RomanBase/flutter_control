import 'dart:convert';

import 'package:control_core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const list = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  const map = <String, int>{
    '0': 0,
    '1': 1,
    '2': 2,
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    '8': 8,
    '9': 9
  };

  group('Parse primitives', () {
    test('string', () {
      expect(Parse.string('val'), 'val');
      expect(Parse.string(10), '10');
      expect(Parse.string(null, defaultValue: 'def'), 'def');
    });

    test('integer', () {
      expect(Parse.toInteger('10'), 10);
      expect(Parse.toInteger('10.1'), 10);
      expect(Parse.toInteger(10.1), 10);
      expect(Parse.toInteger(null, defaultValue: 10), 10);
    });

    test('double', () {
      expect(Parse.toDouble('10'), 10.0);
      expect(Parse.toDouble('10.1'), 10.1);
      expect(Parse.toDouble(10.1), 10.1);
      expect(Parse.toDouble(null, defaultValue: 10), 10.0);
      expect(Parse.toDouble(null, defaultValue: 10.1), 10.1);
    });

    test('bool', () {
      expect(Parse.toBool('true'), isTrue);
      expect(Parse.toBool('false'), isFalse);
      expect(Parse.toBool(true), isTrue);
      expect(Parse.toBool(1), isTrue);
      expect(Parse.toBool(0), isFalse);
      expect(Parse.toBool(1.0), isTrue);
      expect(Parse.toBool(null), isFalse);
      expect(Parse.toBool(null, defaultValue: true), isTrue);
    });

    test('list', () {
      final parse1 = Parse.toList(list);
      final parse2 = Parse.toList<int>(list);
      final parse3 =
          Parse.toList<String>(list, converter: (item) => item.toString());

      final parse4 = Parse.toList(map);
      final parse5 = Parse.toList<int>(map);

      final parse6 =
          Parse.toList<String>(map, converter: (item) => item.toString());
      final parse7 = Parse.toList<String>('value');
      final parse8 =
          Parse.toList<String>(0, converter: (value) => value.toString());

      expect(parse1.length, 10);
      expect(parse2.length, 10);
      expect(parse3.length, 10);
      expect(parse3[0], '0');

      expect(parse4.length, 10);
      expect(parse5.length, 10);
      expect(parse6.length, 10);
      expect(parse7.length, 1);
      expect(parse8.length, 1);

      expect(parse6[0], '0');
      expect(parse7[0], 'value');
      expect(parse8[0], '0');
    });

    test('list entry', () {
      final parse1 = Parse.toList<int>(list,
          entryConverter: (index, value) =>
              Parse.toInteger(index) + Parse.toInteger(value));
      final parse2 = Parse.toList<int>(map,
          entryConverter: (index, value) =>
              Parse.toInteger(index) + Parse.toInteger(value));
      final parse3 = Parse.toList<String>(0,
          entryConverter: (index, value) => value.toString());

      expect(parse1.length, 10);
      expect(parse2.length, 10);
      expect(parse3.length, 1);

      expect(parse1[1], 2);
      expect(parse2[1], 2);
      expect(parse3[0], '0');
    });

    test('map', () {
      final parse1 = Parse.toMap<int, int>(list);
      final parse2 = Parse.toMap<dynamic, int>(list);
      final parse3 = Parse.toMap<dynamic, String>(list,
          converter: (item) => item.toString());

      final parse4 = Parse.toMap<String, int>(map);
      final parse5 = Parse.toMap<dynamic, int>(map);
      final parse6 = Parse.toMap<dynamic, String>(map,
          converter: (item) => item.toString());

      final parse7 = Parse.toMap('value');
      final parse8 = Parse.toMap(0, converter: (value) => value.toString());

      expect(parse1.length, 10);
      expect(parse2.length, 10);
      expect(parse3.length, 10);
      expect(parse3[0], '0');

      expect(parse4.length, 10);
      expect(parse5.length, 10);
      expect(parse6.length, 10);
      expect(parse6['0'], '0');

      expect(parse7.length, 1);
      expect(parse8.length, 1);
      expect(parse7[0], 'value');
      expect(parse8[0], '0');
    });

    test('map entry', () {
      final parse1 = Parse.toMap<dynamic, int>(list,
          entryConverter: (index, value) =>
              Parse.toInteger(index) + Parse.toInteger(value));
      final parse2 = Parse.toMap<dynamic, int>(map,
          entryConverter: (index, value) =>
              Parse.toInteger(index) + Parse.toInteger(value));
      final parse3 = Parse.toMap<dynamic, String>(0,
          entryConverter: (index, value) => value.toString());

      expect(parse1.length, 10);
      expect(parse2.length, 10);
      expect(parse3.length, 1);

      expect(parse1[1], 2);
      expect(parse2['1'], 2);
      expect(parse3[0], '0');
    });
  });

  group('Parse args', () {
    test('list', () {
      final parse0 = Parse.getArgFromList(null, defaultValue: -1);
      final parse1 = Parse.getArgFromList<int>(list);
      final parse2 = Parse.getArgFromList(list, predicate: (item) => item == 5);
      final parse3 = Parse.getArgFromList(list,
          predicate: (item) => item == -1, defaultValue: 10);
      final ext = list.getArg(predicate: (item) => item == 5);

      expect(parse0, -1);
      expect(parse1, 0);
      expect(parse2, 5);
      expect(parse3, 10);
      expect(ext, 5);
    });

    test('map', () {
      final parse0 = Parse.getArgFromMap(null, defaultValue: -1);
      final parse1 = Parse.getArgFromMap<int>(map);
      final parse2 = Parse.getArgFromMap(map, predicate: (item) => item == 5);
      final parse3 = Parse.getArgFromMap(map,
          predicate: (item) => item == -1, defaultValue: 10);
      final parse4 = Parse.getArgFromMap(map, key: int);
      final parse5 = Parse.getArgFromMap(map, key: '5');
      final parse6 = Parse.getArgFromMap<double>(map, defaultValue: -1.0);
      final ext = map.getArg(key: '5');

      expect(parse0, -1);
      expect(parse1, 0);
      expect(parse2, 5);
      expect(parse3, 10);
      expect(parse4, 0);
      expect(parse5, 5);
      expect(parse6, -1.0);
      expect(ext, 5);
    });

    test('string', () {
      final json = jsonEncode(map);

      final parse0 = Parse.getArg(null, defaultValue: 'empty');
      final parse1 = Parse.getArg(json, key: '5');
      final parse2 = Parse.getArg(json, predicate: (item) => item == 5);
      final parse3 = Parse.getArg('null');

      expect(parse0, 'empty');
      expect(parse1, 5);
      expect(parse2, 5);
      expect(parse3, null);
    });

    test('dynamic', () {
      final parse0 = Parse.getArg(null, defaultValue: 'empty');
      final parse1 = Parse.getArg<String>('item');
      final parse2 = Parse.getArg<int>(list);
      final parse3 = Parse.getArg<int>(map);
      final parse4 = Parse.getArg<Iterable>(list);
      final parse5 = Parse.getArg<Map>(map);

      expect(parse0, 'empty');
      expect(parse1, 'item');
      expect(parse2, 0);
      expect(parse3, 0);
      expect(parse4, isNotNull);
      expect(parse5, isNotNull);
    });
  });

  group('Control args', () {
    test('identical list', () {
      final args = ControlArgs.of([1, 2, 3]);

      expect(args.get<List<int>>(), isNotNull);
      expect(args.get<int>(), isNull);
    });

    test('dynamic list', () {
      final args = ControlArgs.of([1, 'a', true]);

      expect(args.get<List>(), isNull);
      expect(args.get<int>(), equals(1));
    });
  });
}
