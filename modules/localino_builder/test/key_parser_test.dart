import 'dart:convert';
import 'dart:io';

import 'package:localino_builder/src/key_model.dart';
import 'package:localino_builder/src/key_parser.dart';
import 'package:test/test.dart';

Map _loadFixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map;

void main() {
  group('inferKind', () {
    test('flat string -> string', () {
      expect(inferKind('Add'), LocalinoKeyKind.string);
    });

    test('string with {param} -> format', () {
      expect(
          inferKind('Version: {version} ({number})'), LocalinoKeyKind.format);
    });

    test('plural-shaped map -> map (no plural split)', () {
      expect(
        inferKind({'0': 'a', '5': 'b', 'other': 'c'}),
        LocalinoKeyKind.map,
      );
    });

    test('value-switch map -> map (no value split)', () {
      expect(
        inferKind({'male': 'boy', 'other': 'child'}),
        LocalinoKeyKind.map,
      );
    });

    test('nested object -> map', () {
      expect(
        inferKind({'title': 'x', 'note': 'y'}),
        LocalinoKeyKind.map,
      );
    });

    test('list -> list', () {
      expect(inferKind(['a', 'b']), LocalinoKeyKind.list);
    });
  });

  group('extractParams', () {
    test('extracts params in order', () {
      expect(
        extractParams('Version: {version} ({number})'),
        ['version', 'number'],
      );
    });

    test('no params -> empty', () {
      expect(extractParams('Add'), isEmpty);
    });
  });

  group('sanitizeIdentifier', () {
    test('leading digit -> prefixed with k', () {
      expect(sanitizeIdentifier('2fa_code'), 'k2fa_code');
    });

    test('reserved word -> trailing underscore', () {
      expect(sanitizeIdentifier('class'), 'class_');
    });

    test('object member clash -> trailing underscore', () {
      expect(sanitizeIdentifier('hashCode'), 'hashCode_');
    });

    test('non-identifier chars -> underscore', () {
      expect(sanitizeIdentifier('menu.item-1'), 'menu_item_1');
    });

    test('plain key unchanged', () {
      expect(sanitizeIdentifier('action_add'), 'action_add');
    });
  });

  group('resolveDefaultLocale', () {
    test('honors init.default_locale', () {
      final setup = {
        'init': {'default_locale': 'cs_CZ'},
        'locales': {'en_US': {}, 'cs_CZ': {}},
      };
      expect(resolveDefaultLocale(setup), 'cs_CZ');
    });

    test('falls back to first locale key', () {
      final setup = {
        'locales': {'en_US': {}, 'cs_CZ': {}},
      };
      expect(resolveDefaultLocale(setup), 'en_US');
    });

    test('throws when nothing resolvable', () {
      expect(() => resolveDefaultLocale({}), throwsStateError);
    });
  });

  group('parseLocalinoKeys', () {
    late List<LocalinoKey> keys;

    setUp(() {
      keys = parseLocalinoKeys(
        {'en_US': _loadFixture('en_US'), 'cs_CZ': _loadFixture('cs_CZ')},
        defaultLocale: 'en_US',
      );
    });

    LocalinoKey byKey(String jsonKey) =>
        keys.firstWhere((k) => k.jsonKey == jsonKey);

    test('sorted alphabetically', () {
      final names = keys.map((k) => k.jsonKey).toList();
      expect(names, List.of(names)..sort());
    });

    test('flat string kind', () {
      expect(byKey('action_add').kind, LocalinoKeyKind.string);
    });

    test('format kind with params', () {
      final k = byKey('version');
      expect(k.kind, LocalinoKeyKind.format);
      expect(k.params, ['version', 'number']);
    });

    test('nested object -> map', () {
      expect(byKey('onboard_card_1').kind, LocalinoKeyKind.map);
    });

    test('plural-shaped -> map', () {
      expect(byKey('plural_items').kind, LocalinoKeyKind.map);
    });

    test('array -> list', () {
      expect(byKey('menu_tabs').kind, LocalinoKeyKind.list);
    });

    test('missing locale detected', () {
      expect(byKey('action_delete_locale').missingLocales, ['cs_CZ']);
    });

    test('present-everywhere key has no missing', () {
      expect(byKey('action_add').missingLocales, isEmpty);
    });

    test('preview is default-locale value', () {
      expect(byKey('action_add').preview, 'Add');
    });

    test('map/list have empty preview', () {
      expect(byKey('onboard_card_1').preview, isEmpty);
      expect(byKey('menu_tabs').preview, isEmpty);
    });

    test('throws when default locale absent', () {
      expect(
        () => parseLocalinoKeys(
          {'en_US': _loadFixture('en_US')},
          defaultLocale: 'de_DE',
        ),
        throwsStateError,
      );
    });

    test('collision throws naming both keys', () {
      expect(
        () => parseLocalinoKeys(
          {
            'en_US': {'menu.item': 'a', 'menu_item': 'b'},
          },
          defaultLocale: 'en_US',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('menu.item'), contains('menu_item')),
          ),
        ),
      );
    });
  });

  test('preview truncated and newline-stripped', () {
    final long = 'a' * 100;
    final keys = parseLocalinoKeys(
      {
        'en_US': {'k': 'line1\nline2   spaced'},
        'x': {'k': '$long'},
      },
      defaultLocale: 'en_US',
    );
    expect(keys.single.preview, 'line1 line2 spaced');
  });
}
