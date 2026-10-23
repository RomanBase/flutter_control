import 'dart:io';

import 'package:localino_builder/src/sync/io.dart';
import 'package:localino_builder/src/sync/merge.dart';
import 'package:test/test.dart';

const _fixture = 'test/fixtures/sync/inbook/assets/localization/cs_CZ.json';
const _key = 'lk_w_AbCdEf123456_0123456789abcdefghijABCDEFGHIJklmnopqrstuvw';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('localino_io'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('locale files', () {
    test(
      'round-trips a 1-space file with plurals, lists and non-ASCII byte for byte',
      () {
        final original = File(_fixture).readAsBytesSync();
        final target = File('${dir.path}/cs_CZ.json')
          ..writeAsBytesSync(original);

        final file = readLocaleFile(target);
        expect(file.indent, ' ');

        writeLocaleFile(target, file);
        expect(target.readAsBytesSync(), original);
      },
    );

    test('second write of the same data is identical bytes', () {
      final target = File('${dir.path}/en.json');
      final data = LocaleFile(
        applyLocaleChanges(
          {'b': 'B'},
          {
            'a': 'Á',
            'c': ['x'],
          },
          {},
        ),
        indent: '  ',
      );

      writeLocaleFile(target, data);
      final first = target.readAsBytesSync();
      writeLocaleFile(target, readLocaleFile(target));

      expect(target.readAsBytesSync(), first);
      expect(target.readAsStringSync(), contains('"a": "Á"'));
    });

    test('keeps key order, appends new keys sorted, removes deleted', () {
      final result = applyLocaleChanges(
        {'z': 1, 'b': 2, 'gone': 3},
        {'b': 20, 'y': 'new', 'a': 'new'},
        {'gone'},
      );

      expect(result.keys, ['z', 'b', 'a', 'y']);
      expect(result['b'], 20);
    });

    test('missing file reads empty with the fallback indent', () {
      final file = readLocaleFile(
        File('${dir.path}/missing.json'),
        fallbackIndent: ' ',
      );
      expect(file.data, isEmpty);
      expect(file.indent, ' ');
    });
  });

  group('lock', () {
    test('round-trips sorted, with no rewrite when unchanged', () {
      final file = File('${dir.path}/.localino/lock.json');
      final lock = Lock({
        'en': {'b': const LockEntry('bb', 2), 'a': const LockEntry('aa', 1)},
        'cs': {'a': const LockEntry('cc', 3)},
        'empty': {},
      });

      writeLock(file, lock);
      final text = file.readAsStringSync();
      final modified = file.lastModifiedSync();

      expect(text.indexOf('"cs"'), lessThan(text.indexOf('"en"')));
      expect(
        text.indexOf('"a"', text.indexOf('"en"')),
        lessThan(text.indexOf('"b"')),
      );
      expect(text, isNot(contains('empty')));
      expect(text, isNot(contains('synced_at')));

      final read = readLock(file);
      expect(read.entry('en', 'b'), const LockEntry('bb', 2));

      writeLock(file, read);
      expect(file.lastModifiedSync(), modified);
      expect(file.readAsStringSync(), text);
    });

    test('missing lock is empty', () {
      expect(readLock(File('${dir.path}/none.json')).locales, isEmpty);
    });
  });

  group('credentials', () {
    test('stored file is mode 600 in a 700 directory and merges projects', () {
      final path = '${dir.path}/.localino/credentials.json';

      storeWriteKey('a', 'one', const WriteKey(_key), credentialsPath: path);
      storeWriteKey('b', 'two', const WriteKey(_key), credentialsPath: path);

      expect(File(path).statSync().mode & 0x1ff, 0x180);
      expect(Directory('${dir.path}/.localino').statSync().mode & 0x1ff, 0x1c0);
      expect(File('$path.tmp').existsSync(), isFalse);
      expect(
        readWriteKey('a', 'one', env: {}, credentialsPath: path)?.value,
        _key,
      );
      expect(
        readWriteKey('b', 'two', env: {}, credentialsPath: path)?.value,
        _key,
      );
      expect(
        readWriteKey('c', 'three', env: {}, credentialsPath: path),
        isNull,
      );
    }, testOn: '!windows');

    test('LOCALINO_WRITE_KEY overrides the file', () {
      final key = readWriteKey(
        'a',
        'one',
        env: {writeKeyEnv: 'lk_w_env'},
        credentialsPath: null,
      );
      expect(key?.value, 'lk_w_env');
    });

    test('WriteKey.toString redacts the secret', () {
      const key = WriteKey(_key);

      expect(WriteKey.isValid(_key), isTrue);
      expect(WriteKey.isValid('9WCDAbyBIhXqH0DwP9lZkAtmxEG2'), isFalse);
      expect(key.toString(), 'WriteKey(lk_w_AbCdEf123456_***)');
      expect('$key', isNot(contains('0123456789')));
    });
  });
}
