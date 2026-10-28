import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:localino_builder/src/config.dart';
import 'package:localino_builder/src/sync/io.dart';
import 'package:localino_builder/src/sync/merge.dart';
import 'package:localino_builder/src/sync/sync_engine.dart';
import 'package:test/test.dart';

import '../support/fake_localino.dart';

const _read = fakeReadToken;
const _write = fakeWriteKey;
const _cs = 'cs_CZ';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('localino_engine');
    File('${root.path}/$setupJsonPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'space': 'sp',
          'project': 'pr',
          'access': _read,
          'asset': defaultAssetPath,
          'locales': {_cs: ''},
        }),
      );
  });

  tearDown(() => root.deleteSync(recursive: true));

  File localeFile([String locale = _cs]) =>
      File('${root.path}/assets/localization/$locale.json');
  File lockFile() => File('${root.path}/$lockPath');

  void writeLocal(Map<String, dynamic> data, [String locale = _cs]) =>
      localeFile(locale).writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(data)}\n',
      );

  Map readLocal([String locale = _cs]) =>
      jsonDecode(localeFile(locale).readAsStringSync()) as Map;

  void writeLockOf(Map<String, (dynamic, int)> entries) => writeLock(
    lockFile(),
    Lock({
      _cs: {
        for (final e in entries.entries)
          e.key: LockEntry(valueHash(e.value.$1), e.value.$2),
      },
    }),
  );

  SyncEngine engine(
    FakeLocalino fake, {
    Map<String, String>? env,
    bool generateKeys = false,
  }) {
    final config = loadConfig(root: root.path)!;

    return SyncEngine(
      config:
          generateKeys
              ? LocalinoConfig(
                space: config.space,
                project: config.project,
                access: config.access,
                root: config.root,
                generateKeys: true,
              )
              : config,
      client: fake.client,
      apiUrl: Uri.parse('https://api.test/v1'),
      env: env ?? {writeKeyEnv: _write},
    );
  }

  group('pull', () {
    test('applies remote edits and keeps local-only keys', () async {
      writeLocal({
        'a': 'A',
        'local_only': 'L',
        'plural': {'1': 'x', 'other': 'y'},
      });
      writeLockOf({
        'a': ('A', 1),
        'plural': ({'other': 'y', '1': 'x'}, 1),
      });
      final fake = FakeLocalino({
        _cs: {
          'a': ('A2', 5),
          'plural': ({'1': 'x', 'other': 'y'}, 1),
          'remote_new': ('R', 6),
        },
      });

      final result = await engine(fake).pull();

      expect(result.exitCode, SyncExit.ok);
      expect(readLocal(), {
        'a': 'A2',
        'local_only': 'L',
        'plural': {'1': 'x', 'other': 'y'},
        'remote_new': 'R',
      });
      expect(readLocal().keys.last, 'remote_new');

      final lock = readLock(lockFile());
      expect(lock.entry(_cs, 'a'), LockEntry(valueHash('A2'), 5));
      expect(lock.entry(_cs, 'remote_new'), LockEntry(valueHash('R'), 6));
      expect(lock.entry(_cs, 'local_only'), isNull);
      expect(result.localFilesChanged, isTrue);
    });

    test('second pull changes nothing', () async {
      writeLocal({'x': 'X'});
      final fake = FakeLocalino({
        _cs: {'a': ('A2', 5)},
      });

      await engine(fake).pull();
      final file = localeFile().readAsStringSync();
      final lock = lockFile().readAsStringSync();
      final second = await engine(fake).pull();

      expect(second.pulled, isEmpty);
      expect(second.localFilesChanged, isFalse);
      expect(localeFile().readAsStringSync(), file);
      expect(lockFile().readAsStringSync(), lock);
    });

    test('conflict exits 3 and writes nothing', () async {
      writeLocal({'a': 'mine'});
      writeLockOf({'a': ('A', 1)});
      final before = lockFile().readAsStringSync();
      final fake = FakeLocalino({
        _cs: {'a': ('theirs', 2), 'b': ('B', 2)},
      });

      final result = await engine(fake).pull();

      expect(result.exitCode, SyncExit.conflict);
      expect(result.conflicts.single, containsPair('key', 'a'));
      expect(readLocal(), {'a': 'mine'});
      expect(lockFile().readAsStringSync(), before);
      // `b` would be pulled, but the stopped run reports nothing as written.
      expect(result.pulled, isEmpty);
      expect(result.localFilesChanged, false);
    });

    test('prefer remote resolves the conflict', () async {
      writeLocal({'a': 'mine'});
      writeLockOf({'a': ('A', 1)});
      final fake = FakeLocalino({
        _cs: {'a': ('theirs', 2)},
      });

      final result = await engine(fake).pull(prefer: Prefer.remote);

      expect(result.exitCode, SyncExit.ok);
      expect(readLocal(), {'a': 'theirs'});
    });

    test('dry run writes nothing', () async {
      writeLocal({'a': 'A'});
      final fake = FakeLocalino({
        _cs: {'b': ('B', 2)},
      });

      final result = await engine(fake).pull(dryRun: true);

      expect(result.pulled.single.key, 'b');
      expect(readLocal(), {'a': 'A'});
      expect(lockFile().existsSync(), isFalse);
    });

    test('regenerates typed keys when generate_keys is on', () async {
      writeLocal({'a': 'A'});
      final fake = FakeLocalino({
        _cs: {'b': ('B', 2)},
      });

      final result = await engine(fake, generateKeys: true).pull();

      expect(result.generatedKeys, keysOutputPath);
      expect(
        File('${root.path}/$keysOutputPath').readAsStringSync(),
        contains("static const b = 'b';"),
      );
    });
  });

  group('push', () {
    test('a same-value `unchanged` answer re-stamps the lock', () async {
      writeLocal({'a': 'B'});
      writeLockOf({'a': ('A', 1)});
      final fake = FakeLocalino({
          _cs: {'a': ('A', 1)},
        })
        ..pushResponses[0] = FakeLocalino.json(200, {
          'dry_run': false,
          'applied': [],
          'unchanged': [
            {'locale': _cs, 'key': 'a', 'ts': 9},
          ],
          'rejected_locked': [],
        });

      final result = await engine(fake).push();

      expect(result.exitCode, SyncExit.ok);
      expect(
        readLock(lockFile()).entry(_cs, 'a'),
        LockEntry(valueHash('B'), 9),
      );
    });

    test('a key Localino types differently is reported, not sent', () async {
      writeLocal({
        'days': {'one': 'den', 'other': 'dní'},
        'new': 'N',
      });
      final fake = FakeLocalino({
        _cs: {'days': ('dny', 2)},
      });

      final result = await engine(fake).push(prefer: Prefer.local);

      expect(result.exitCode, SyncExit.conflict);
      expect(result.typeMismatches.single['key'], 'days');
      expect(result.pushed, isEmpty);
      expect(fake.pushes, isEmpty);
      expect(lockFile().existsSync(), isFalse);
    });

    test('sends local edits and records the server ts in the lock', () async {
      writeLocal({'a': 'A2', 'new_key': 'N'});
      writeLockOf({'a': ('A', 3)});
      final fake = FakeLocalino({
        _cs: {'a': ('A', 3)},
      });

      final result = await engine(fake).push();

      expect(result.exitCode, SyncExit.ok);
      expect(result.pushed.map((e) => e['key']), ['a', 'new_key']);
      expect(fake.translations[_cs]!['new_key'], ('N', 1000));

      final body = jsonDecode(fake.pushes.single.body) as Map;
      expect(body['dry_run'], isFalse);
      expect(body['changes'], [
        {'locale': _cs, 'key': 'a', 'value': 'A2', 'base_ts': 3},
        {'locale': _cs, 'key': 'new_key', 'value': 'N', 'base_ts': null},
      ]);
      expect(
        readLock(lockFile()).entry(_cs, 'new_key'),
        LockEntry(valueHash('N'), 1000),
      );
    });

    test('never sends deletes without --prune', () async {
      writeLocal({'kept': 'K'});
      writeLockOf({'kept': ('K', 1), 'gone': ('G', 1)});
      final fake = FakeLocalino({
        _cs: {'kept': ('K', 1), 'gone': ('G', 1)},
      });

      final result = await engine(fake).push();

      expect(fake.pushes, isEmpty);
      expect(result.skippedDeletes.single.key, 'gone');
      expect(fake.translations[_cs]!.containsKey('gone'), isTrue);

      await engine(fake).push(prune: true);

      expect((jsonDecode(fake.pushes.single.body) as Map)['changes'], [
        {'locale': _cs, 'key': 'gone', 'delete': true, 'base_ts': 1},
      ]);
      expect(fake.translations[_cs]!.containsKey('gone'), isFalse);
      expect(readLock(lockFile()).entry(_cs, 'gone'), isNull);
    });

    test('write key goes only in Authorization, and only on push', () async {
      writeLocal({'a': 'A'});
      final fake = FakeLocalino({_cs: {}});

      await engine(fake).push();

      final snapshot = fake.requests.firstWhere(
        (e) => e.url.path.endsWith('/snapshot'),
      );
      final push = fake.pushes.single;

      expect(snapshot.headers['access'], _read);
      expect(snapshot.headers.containsKey('authorization'), isFalse);
      expect(push.headers['authorization'], 'Bearer $_write');
      expect(push.headers.containsKey('access'), isFalse);

      for (final request in fake.requests) {
        expect(request.url.toString(), isNot(contains(_write)));
        expect(request.body, isNot(contains(_write)));
      }
    });

    test(
      'missing write key exits 4 with zero requests (push and sync)',
      () async {
        writeLocal({'a': 'A'});
        final fake = FakeLocalino({_cs: {}});

        for (final run in [
          () => engine(fake, env: {}).push(),
          () => engine(fake, env: {}).sync(),
        ]) {
          await expectLater(
            run(),
            throwsA(
              isA<SyncException>().having(
                (e) => e.exitCode,
                'exitCode',
                SyncExit.auth,
              ),
            ),
          );
        }

        expect(fake.requests, isEmpty);
      },
    );

    test(
      'malformed write key (e.g. the read token) exits 4 with zero requests',
      () async {
        final fake = FakeLocalino({_cs: {}});

        await expectLater(
          engine(fake, env: {writeKeyEnv: _read}).push(),
          throwsA(
            isA<SyncException>().having(
              (e) => e.exitCode,
              'exitCode',
              SyncExit.auth,
            ),
          ),
        );
        expect(fake.requests, isEmpty);
      },
    );

    test('server error leaves the lock untouched and exits 5', () async {
      writeLocal({'a': 'A'});
      final fake = FakeLocalino({_cs: {}})
        ..pushResponses[0] = http.Response('boom', 503);

      await expectLater(
        engine(fake).push(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.exitCode,
            'exitCode',
            SyncExit.network,
          ),
        ),
      );
      expect(lockFile().existsSync(), isFalse);
    });

    test('lock is updated per successful chunk', () async {
      writeLocal({
        for (var i = 0; i < maxNewKeys + 1; i++)
          'k${'$i'.padLeft(4, '0')}': 'v',
      });
      final fake = FakeLocalino({_cs: {}})
        ..pushResponses[1] = http.Response('boom', 503);

      await expectLater(engine(fake).push(), throwsA(isA<SyncException>()));

      final lock = readLock(lockFile());
      expect(fake.pushes.length, 2);
      expect(lock.locales[_cs]!.length, maxNewKeys);
      expect(lock.entry(_cs, 'k0400'), isNull);
    });

    test('401 exits 4, contention exits 5, server conflict exits 3', () async {
      writeLocal({'a': 'A'});

      final unauthorized = FakeLocalino({_cs: {}})
        ..pushResponses[0] = FakeLocalino.json(401, {'error': 'unauthorized'});
      await expectLater(
        engine(unauthorized).push(),
        throwsA(
          isA<SyncException>()
              .having((e) => e.exitCode, 'exitCode', SyncExit.auth)
              .having((e) => e.message, 'message', isNot(contains(_write))),
        ),
      );

      final contention = FakeLocalino({_cs: {}})
        ..pushResponses[0] = FakeLocalino.json(409, {'error': 'contention'});
      await expectLater(
        engine(contention).push(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.exitCode,
            'exitCode',
            SyncExit.network,
          ),
        ),
      );

      final conflict = FakeLocalino({_cs: {}})
        ..pushResponses[0] = FakeLocalino.json(409, {
          'error': 'conflict',
          'conflicts': [
            {
              'locale': _cs,
              'key': 'a',
              'base_ts': null,
              'remote_ts': 9,
              'remote_value': 'X',
            },
          ],
        });
      final result = await engine(conflict).push();
      expect(result.exitCode, SyncExit.conflict);
      expect(lockFile().existsSync(), isFalse);
    });

    test('type mismatch (422) exits 3', () async {
      writeLocal({'a': 'A'});
      final fake = FakeLocalino({_cs: {}})
        ..pushResponses[0] = FakeLocalino.json(422, {
          'error': 'invalid',
          'details': [
            {'locale': _cs, 'key': 'a', 'reason': 'type_mismatch'},
          ],
        });

      await expectLater(
        engine(fake).push(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.exitCode,
            'exitCode',
            SyncExit.conflict,
          ),
        ),
      );
    });

    test('dry run asks the server to validate and writes no lock', () async {
      writeLocal({'a': 'A'});
      final fake = FakeLocalino({_cs: {}});

      final result = await engine(fake).push(dryRun: true);

      expect((jsonDecode(fake.pushes.single.body) as Map)['dry_run'], isTrue);
      expect(result.pushed.single['ts'], isNull);
      expect(fake.translations[_cs], isEmpty);
      expect(lockFile().existsSync(), isFalse);
    });

    test('locked keys are reported and not locked in the lock file', () async {
      writeLocal({'a': 'A2'});
      writeLockOf({'a': ('A', 1)});
      final fake = FakeLocalino(
        {
          _cs: {'a': ('A', 1)},
        },
        locked: {'a'},
      );

      final result = await engine(fake).push();

      expect(result.rejectedLocked.single['key'], 'a');
      expect(
        readLock(lockFile()).entry(_cs, 'a'),
        LockEntry(valueHash('A'), 1),
      );
    });
  });

  group('sync', () {
    test(
      'invalid keys or values stop before the pull: exit 1, nothing written',
      () async {
        writeLocal({'bad key': 'x', 'count': 3});
        final fake = FakeLocalino({
          _cs: {'remote': ('R', 2)},
        });

        final result = await engine(fake).sync();

        expect(result.exitCode, SyncExit.error);
        expect(result.invalid.map((e) => e['reason']), [
          'invalid_key',
          'unsupported_value',
        ]);
        expect(fake.pushes, isEmpty);
        expect(readLocal(), {'bad key': 'x', 'count': 3});
        expect(lockFile().existsSync(), isFalse);
      },
    );

    test('reports the deletes the push skipped', () async {
      writeLocal({});
      writeLockOf({'gone': ('G', 1)});
      final fake = FakeLocalino({
        _cs: {'gone': ('G', 1)},
      });

      final result = await engine(fake).sync();

      expect(result.skippedDeletes.single.key, 'gone');
      expect(fake.translations[_cs], contains('gone'));
    });

    test('pulls then pushes; a second sync is a no-op', () async {
      writeLocal({'local': 'L'});
      final fake = FakeLocalino({
        _cs: {'remote': ('R', 2)},
      });

      final result = await engine(fake).sync();

      expect(result.exitCode, SyncExit.ok);
      expect(result.pulled.single.key, 'remote');
      expect(result.pushed.single['key'], 'local');
      expect(readLocal(), {'local': 'L', 'remote': 'R'});

      final file = localeFile().readAsStringSync();
      final lock = lockFile().readAsStringSync();
      final second = await engine(fake).sync();

      expect(second.pulled, isEmpty);
      expect(second.pushed, isEmpty);
      expect(localeFile().readAsStringSync(), file);
      expect(lockFile().readAsStringSync(), lock);
    });

    test('push failure exits 5 with the pull applied', () async {
      writeLocal({'local': 'L'});
      final fake = FakeLocalino({
        _cs: {'remote': ('R', 2)},
      })..pushResponses[0] = http.Response('boom', 500);

      await expectLater(
        engine(fake).sync(),
        throwsA(
          isA<SyncException>()
              .having((e) => e.exitCode, 'exitCode', SyncExit.network)
              .having((e) => e.message, 'message', contains('push pending')),
        ),
      );

      expect(readLocal(), {'local': 'L', 'remote': 'R'});
      expect(
        readLock(lockFile()).entry(_cs, 'remote'),
        LockEntry(valueHash('R'), 2),
      );
    });

    test(
      'type mismatch stops before the pull: exit 3, nothing written, nothing sent',
      () async {
        const plural = {'1': 'den', '2': 'dny', '5': 'dní', 'other': 'dní'};
        writeLocal({'days': plural});
        final fake = FakeLocalino({
          _cs: {'days': ('dny', 2), 'remote': ('R', 3)},
        });

        final result = await engine(fake).sync(prefer: Prefer.local);

        expect(result.exitCode, SyncExit.conflict);
        expect(result.typeMismatches.single, {
          'locale': _cs,
          'key': 'days',
          'local_value': plural,
          'remote_type': 'text',
        });
        expect(fake.pushes, isEmpty);
        expect(readLocal(), {
          'days': plural,
        }, reason: 'remote-only key not pulled');
        expect(lockFile().existsSync(), isFalse);
      },
    );

    test('a push rejected for auth after the pull keeps exit 4', () async {
      writeLocal({'local': 'L'});
      final fake = FakeLocalino({
        _cs: {'remote': ('R', 2)},
      })..pushResponses[0] = FakeLocalino.json(401, {'error': 'unauthorized'});

      await expectLater(
        engine(fake).sync(),
        throwsA(
          isA<SyncException>()
              .having((e) => e.exitCode, 'exitCode', SyncExit.auth)
              .having((e) => e.message, 'message', contains('push failed')),
        ),
      );
      expect(readLocal(), {'local': 'L', 'remote': 'R'});
    });

    test(
      'conflict exits 3 with both sides unchanged; prefer local resolves by pushing',
      () async {
        writeLocal({'a': 'mine'});
        writeLockOf({'a': ('A', 1)});
        final fake = FakeLocalino({
          _cs: {'a': ('theirs', 2)},
        });

        final stopped = await engine(fake).sync();
        expect(stopped.exitCode, SyncExit.conflict);
        expect(fake.pushes, isEmpty);
        expect(readLocal(), {'a': 'mine'});

        final resolved = await engine(fake).sync(prefer: Prefer.local);
        expect(resolved.exitCode, SyncExit.ok);
        expect(fake.translations[_cs]!['a']!.$1, 'mine');
        expect(readLocal(), {'a': 'mine'});
      },
    );
  });

  group('status', () {
    test('reports each state', () async {
      writeLocal({'same': 'S', 'mine': 'M2', 'new_local': 'N', 'theirs': 'T'});
      writeLockOf({'same': ('S', 1), 'mine': ('M', 1), 'theirs': ('T', 1)});
      final fake = FakeLocalino({
        _cs: {'same': ('S', 1), 'mine': ('M', 1), 'theirs': ('T2', 2)},
      });

      final result = await engine(fake).status();

      expect(result.remoteKnown, isTrue);
      expect(result.counts[KeyState.unchanged], 1);
      expect(result.counts[KeyState.localChanged], 2);
      expect(result.counts[KeyState.remoteChanged], 1);
      expect(result.changes.map((e) => e.key), ['mine', 'new_local', 'theirs']);
    });

    test('offline compares local vs lock only', () async {
      writeLocal({'same': 'S', 'mine': 'M2'});
      writeLockOf({'same': ('S', 1), 'mine': ('M', 1)});
      final offline = SyncEngine(
        config: loadConfig(root: root.path)!,
        client: MockClient((_) async => throw http.ClientException('offline')),
        apiUrl: Uri.parse('https://api.test/v1'),
      );

      final result = await offline.status();

      expect(result.remoteKnown, isFalse);
      expect(result.changes.single.key, 'mine');
      expect(result.changes.single.state, KeyState.localChanged);
    });

    test('pull offline exits 5 and leaves files untouched', () async {
      writeLocal({'a': 'A'});
      final offline = SyncEngine(
        config: loadConfig(root: root.path)!,
        client: MockClient((_) async => throw const SocketException('offline')),
        apiUrl: Uri.parse('https://api.test/v1'),
      );

      await expectLater(
        offline.pull(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.exitCode,
            'exitCode',
            SyncExit.network,
          ),
        ),
      );
      expect(readLocal(), {'a': 'A'});
    });

    test('local locales unknown to Localino are skipped', () async {
      writeLocal({'a': 'A'});
      writeLocal({'b': 'B'}, 'de_DE');
      final fake = FakeLocalino({
        _cs: {'a': ('A', 1)},
      });

      final result = await engine(fake).status();
      expect(result.unknownLocales, ['de_DE']);
    });
  });

  test('a non-https API URL is refused before any request', () {
    expect(
      () => resolveApiUrl({'LOCALINO_API_URL': 'http://capture.example/v1'}),
      throwsA(isA<ConfigException>()),
    );
  });

  group('add locales', () {
    const de = 'de_DE';

    test(
      'a local locale Localino lacks is skipped, listed by a dry run, then created and pushed',
      () async {
        writeLocal({'a': 'A'});
        writeLocal({'a': 'Hallo'}, de);
        final fake = FakeLocalino({_cs: {}});

        final skipped = await engine(fake).push();

        expect(skipped.unknownLocales, [de]);
        expect(skipped.addedLocales, isEmpty);
        expect(fake.localeRequests, isEmpty);

        final preview = await engine(fake).push(dryRun: true, addLocales: true);

        expect(preview.addedLocales, [de]);
        expect(jsonDecode(fake.localeRequests.single.body), {
          'dry_run': true,
          'locales': [
            {'locale': de},
          ],
        });
        expect(fake.translations.keys, [_cs]);

        final applied = await engine(fake).push(addLocales: true);

        expect(applied.addedLocales, [de]);
        expect(applied.unknownLocales, isEmpty);
        expect(applied.pushed, [containsPair('locale', de)]);
        expect(fake.translations[de]!['a']!.$1, 'Hallo');
      },
    );

    test(
      'anything the push would reject in a new locale stops before the locale is created',
      () async {
        writeLocal({});
        writeLocal({'bad key': 'x'}, de);
        final fake = FakeLocalino({_cs: {}});

        final result = await engine(fake).push(addLocales: true);

        expect(result.invalid, [containsPair('locale', de)]);
        expect(result.exitCode, SyncExit.error);
        expect(fake.localeRequests, isEmpty);
        expect(fake.pushes, isEmpty);
      },
    );

    test('sync creates the locale, then pulls and pushes', () async {
      writeLocal({'a': 'A'});
      writeLocal({'a': 'Hallo'}, de);
      final fake = FakeLocalino({
        _cs: {'r': ('R', 5)},
      });

      final result = await engine(fake).sync(addLocales: true);

      expect(result.exitCode, SyncExit.ok);
      expect(result.addedLocales, [de]);
      expect(readLocal()['r'], 'R');
      expect(fake.translations[de]!['a']!.$1, 'Hallo');
    });
  });

  test(
    'a Localino locale that differs from a local file only in case stops every command',
    () async {
      writeLocal({'a': 'A'});
      final before = readLocal();
      final fake = FakeLocalino({
        'cs_cz': {'r': ('R', 5)},
      });

      for (final run in [
        () => engine(fake).status(),
        () => engine(fake).pull(),
        () => engine(fake).push(),
        () => engine(fake).sync(),
      ]) {
        await expectLater(
          run(),
          throwsA(
            isA<SyncException>()
                .having((e) => e.exitCode, 'exitCode', SyncExit.error)
                .having(
                  (e) => e.message,
                  'message',
                  contains('`cs_cz`, the local file is `cs_CZ`'),
                ),
          ),
        );
      }
      expect(readLocal(), before);
      expect(lockFile().existsSync(), false);
      expect(fake.pushes, isEmpty);
    },
  );
}
