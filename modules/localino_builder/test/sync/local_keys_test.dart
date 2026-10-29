import 'package:localino_builder/src/sync/local_keys.dart';
import 'package:test/test.dart';

void main() {
  final files = <String, Map<String, dynamic>>{
    'cs_CZ': {
      'pay': 'Zaplatit',
      'pay_now': 'Zaplatit teď',
      'pay_copy': 'Zaplatit',
      'days': {'one': 'den', 'other': 'dní'},
      'blank': ' ',
    },
    'en_US': {'pay': 'Pay', 'pay_now': 'Pay now', 'pay_copy': 'Pay'},
  };

  group('searchKeys', () {
    test('exact value matches first, with keys holding the same value', () {
      final result = searchKeys(files, query: 'zaplatit');
      final matches = result['matches'] as List;

      expect(matches.map((e) => e['key']), ['pay', 'pay_copy', 'pay_now']);
      expect(matches.first['exact_value_match'], isTrue);
      expect(matches.first['same_value_as'], ['pay_copy']);
      expect(matches.last.containsKey('exact_value_match'), isFalse);
    });

    test('matches key names and map values', () {
      expect(
        (searchKeys(files, query: 'DNÍ')['matches'] as List).single['key'],
        'days',
      );
      expect(searchKeys(files, query: 'pay_n')['total'], 1);
    });

    test('missing_in finds keys absent or blank in a locale', () {
      final result = searchKeys(files, missingIn: 'en_US');

      expect((result['matches'] as List).map((e) => e['key']), [
        'blank',
        'days',
      ]);
    });

    test('exact keys report the unknown ones; limit truncates', () {
      final result = searchKeys(files, keys: {'pay', 'nope'}, limit: 1);

      expect(result['not_found'], ['nope']);
      expect(searchKeys(files, limit: 2)['truncated'], isTrue);
    });
  });

  group('planSetKeys', () {
    test('diffs adds, updates and removes; same value is no change', () {
      final plan = planSetKeys(
        files,
        [
          (key: 'pay', values: {'cs_CZ': 'Zaplatit', 'en_US': 'Pay up'}),
          (key: 'new_key', values: {'cs_CZ': 'Nový'}),
        ],
        {'pay_copy'},
      );

      expect(plan.errors, isEmpty);
      expect(plan.diff, [
        {'locale': 'cs_CZ', 'key': 'new_key', 'change': 'added', 'new': 'Nový'},
        {
          'locale': 'cs_CZ',
          'key': 'pay_copy',
          'change': 'removed',
          'old': 'Zaplatit',
        },
        {
          'locale': 'en_US',
          'key': 'pay',
          'change': 'updated',
          'old': 'Pay',
          'new': 'Pay up',
        },
        {
          'locale': 'en_US',
          'key': 'pay_copy',
          'change': 'removed',
          'old': 'Pay',
        },
      ]);
      expect(plan.locales, {'cs_CZ', 'en_US'});
      expect(plan.incomplete, [
        {
          'key': 'new_key',
          'missing_in': ['en_US'],
        },
      ]);
    });

    test(
      'rejects bad keys, unknown locales, scalars and set+remove together',
      () {
        final plan = planSetKeys(
          files,
          [
            (key: 'bad key', values: {'cs_CZ': 'x'}),
            (key: 'k', values: {'de_DE': 'x', 'cs_CZ': 42}),
            (key: 'pay', values: {'cs_CZ': 'x'}),
          ],
          {'pay'},
        );

        expect(plan.errors, hasLength(4));
        expect(plan.diff, isEmpty);
        expect(plan.changed, isFalse);
      },
    );

    test('is a no-op when values already match', () {
      final plan = planSetKeys(files, [
        (key: 'pay', values: {'cs_CZ': 'Zaplatit', 'en_US': 'Pay'}),
      ], {});

      expect(plan.changed, isFalse);
      expect(plan.incomplete, isEmpty);
    });
  });

  test('isEmptyValue', () {
    for (final empty in [null, '', '  ', <String>[], <String, String>{}]) {
      expect(isEmptyValue(empty), isTrue, reason: '$empty');
    }
    expect(isEmptyValue('x'), isFalse);
  });
}
