import 'package:localino_builder/src/sync/merge.dart';
import 'package:test/test.dart';

const _l = 'cs_CZ';

LockEntry _lock(dynamic value, [int ts = 1]) => LockEntry(valueHash(value), ts);

/// Classifies one key in one locale. Absent sides are null; [remote] is `(value, ts)`.
KeyDiff _one({
  dynamic local,
  LockEntry? lock,
  (dynamic, int)? remote,
  bool offline = false,
}) {
  final diffs = classify(
    local: {
      _l: {if (local != null) 'k': local},
    },
    lock: Lock({
      _l: {if (lock != null) 'k': lock},
    }),
    remote:
        offline
            ? null
            : {
              _l: {if (remote != null) 'k': RemoteEntry(remote.$1, remote.$2)},
            },
  );

  return diffs.single;
}

void main() {
  group('valueHash', () {
    test('ignores map key order (plural maps)', () {
      expect(
        valueHash({'1': 'rok', 'other': 'let'}),
        valueHash({'other': 'let', '1': 'rok'}),
      );
    });

    test('distinguishes value shapes', () {
      expect(valueHash('a'), isNot(valueHash(['a'])));
      expect(valueHash(['a', 'b']), isNot(valueHash(['b', 'a'])));
    });
  });

  group('classify with lock', () {
    test('unchanged', () {
      expect(
        _one(local: 'A', lock: _lock('A'), remote: ('A', 1)).state,
        KeyState.unchanged,
      );
    });

    test('local modified', () {
      final diff = _one(local: 'B', lock: _lock('A'), remote: ('A', 1));
      expect(diff.state, KeyState.localChanged);
      expect(diff.added, isFalse);
      expect(diff.deleted, isFalse);
    });

    test('local deleted', () {
      final diff = _one(lock: _lock('A'), remote: ('A', 1));
      expect(diff.state, KeyState.localChanged);
      expect(diff.deleted, isTrue);
    });

    test('remote modified', () {
      expect(
        _one(local: 'A', lock: _lock('A'), remote: ('B', 2)).state,
        KeyState.remoteChanged,
      );
    });

    test('remote deleted', () {
      final diff = _one(local: 'A', lock: _lock('A'));
      expect(diff.state, KeyState.remoteChanged);
      expect(diff.deleted, isTrue);
    });

    test('converged: same change on both sides', () {
      expect(
        _one(local: 'B', lock: _lock('A'), remote: ('B', 2)).state,
        KeyState.converged,
      );
    });

    test('converged: deleted on both sides', () {
      expect(_one(lock: _lock('A')).state, KeyState.converged);
    });

    test('conflict: both modified differently', () {
      expect(
        _one(local: 'B', lock: _lock('A'), remote: ('C', 2)).state,
        KeyState.conflict,
      );
    });

    test('conflict: deleted locally, modified remotely', () {
      expect(_one(lock: _lock('A'), remote: ('C', 2)).state, KeyState.conflict);
    });

    test('conflict: modified locally, deleted remotely', () {
      expect(_one(local: 'B', lock: _lock('A')).state, KeyState.conflict);
    });

    test('plural map with reordered keys is unchanged', () {
      final diff = _one(
        local: {'other': '{n} let', '1': '{n} rok'},
        lock: _lock({'1': '{n} rok', 'other': '{n} let'}),
        remote: ({'1': '{n} rok', 'other': '{n} let'}, 1),
      );
      expect(diff.state, KeyState.unchanged);
    });

    test('legacy remote (ts 0) equal to lock is unchanged', () {
      expect(
        _one(local: 'A', lock: _lock('A', 0), remote: ('A', 0)).state,
        KeyState.unchanged,
      );
    });

    test('legacy remote (ts 0) changed is remoteChanged', () {
      expect(
        _one(local: 'A', lock: _lock('A', 0), remote: ('B', 0)).state,
        KeyState.remoteChanged,
      );
    });
  });

  group('classify without lock (first adoption)', () {
    test('equal values → converged baseline', () {
      expect(_one(local: 'A', remote: ('A', 1)).state, KeyState.converged);
    });

    test('local only → local added', () {
      final diff = _one(local: 'A');
      expect(diff.state, KeyState.localChanged);
      expect(diff.added, isTrue);
    });

    test('remote only → remote added', () {
      final diff = _one(remote: ('A', 1));
      expect(diff.state, KeyState.remoteChanged);
      expect(diff.added, isTrue);
    });

    test('different values → conflict', () {
      expect(_one(local: 'A', remote: ('B', 1)).state, KeyState.conflict);
    });
  });

  group('classify offline (remote unknown)', () {
    test('local equal to lock → unchanged', () {
      expect(
        _one(local: 'A', lock: _lock('A'), offline: true).state,
        KeyState.unchanged,
      );
    });

    test('local edit → localChanged', () {
      expect(
        _one(local: 'B', lock: _lock('A'), offline: true).state,
        KeyState.localChanged,
      );
    });

    test('local add → localChanged added', () {
      expect(_one(local: 'B', offline: true).added, isTrue);
    });
  });

  test('classify covers every locale and key, sorted', () {
    final diffs = classify(
      local: {
        'en': {'b': 'B'},
      },
      lock: Lock({}),
      remote: {
        'cs': {'a': const RemoteEntry('A', 1)},
        'en': {'a': const RemoteEntry('A', 1)},
      },
    );

    expect(diffs.map((e) => '${e.locale}/${e.key}'), ['cs/a', 'en/a', 'en/b']);
  });

  group('planPull', () {
    final remoteChanged = _one(local: 'A', lock: _lock('A'), remote: ('B', 2));
    final localChanged = _one(local: 'B', lock: _lock('A'), remote: ('A', 1));
    final converged = _one(local: 'A', remote: ('A', 1));
    final restamped = _one(local: 'A', lock: _lock('A', 1), remote: ('A', 9));
    final conflict = _one(local: 'B', lock: _lock('A'), remote: ('C', 2));

    test(
      'applies remote changes, baselines converged and re-stamped, keeps local changes',
      () {
        final plan = planPull([
          remoteChanged,
          localChanged,
          converged,
          restamped,
        ]);

        expect(plan.updates, [remoteChanged]);
        expect(plan.baseline, [converged, restamped]);
        expect(plan.conflicts, isEmpty);
      },
    );

    test('conflicts are reported without prefer', () {
      expect(planPull([conflict]).conflicts, [conflict]);
    });

    test('prefer remote takes the remote side', () {
      final plan = planPull([conflict], prefer: Prefer.remote);
      expect(plan.updates, [conflict]);
      expect(plan.conflicts, isEmpty);
    });

    test('prefer local leaves the conflict for push', () {
      final plan = planPull([conflict], prefer: Prefer.local);
      expect(plan.updates, isEmpty);
      expect(plan.conflicts, isEmpty);
    });
  });

  group('planPush', () {
    test(
      'sends local edits with the remote ts as base_ts; new keys with null',
      () {
        final edit = _one(local: 'B', lock: _lock('A'), remote: ('A', 7));
        final added = _one(local: 'N');
        final plan = planPush([edit, added], remoteKeys: {'k'});

        expect(plan.chunks.single.map((e) => e.toJson()), [
          {'locale': _l, 'key': 'k', 'value': 'B', 'base_ts': 7},
          {'locale': _l, 'key': 'k', 'value': 'N', 'base_ts': null},
        ]);
      },
    );

    test('never sends deletes without prune', () {
      final deleted = _one(lock: _lock('A'), remote: ('A', 7));
      final plan = planPush([deleted], remoteKeys: {'k'});

      expect(plan.chunks, isEmpty);
      expect(plan.skippedDeletes, [deleted]);
    });

    test('sends deletes with prune', () {
      final deleted = _one(lock: _lock('A'), remote: ('A', 7));
      final plan = planPush([deleted], prune: true, remoteKeys: {'k'});

      expect(plan.chunks.single.single.toJson(), {
        'locale': _l,
        'key': 'k',
        'delete': true,
        'base_ts': 7,
      });
    });

    test('ignores remote-only changes', () {
      expect(
        planPush(
          [_one(local: 'A', lock: _lock('A'), remote: ('B', 2))],
          remoteKeys: {'k'},
        ).chunks,
        isEmpty,
      );
    });

    test('conflict stops the push unless prefer local', () {
      final conflict = _one(local: 'B', lock: _lock('A'), remote: ('C', 4));

      final stopped = planPush([conflict], remoteKeys: {'k'});
      expect(stopped.conflicts, [conflict]);
      expect(stopped.chunks, isEmpty);

      expect(
        planPush(
          [conflict],
          prefer: Prefer.remote,
          remoteKeys: {'k'},
        ).changeCount,
        0,
      );

      final forced = planPush(
        [conflict],
        prefer: Prefer.local,
        remoteKeys: {'k'},
      );
      expect(forced.chunks.single.single.toJson(), {
        'locale': _l,
        'key': 'k',
        'value': 'B',
        'base_ts': 4,
      });
    });

    test(
      'a value whose shape the Localino key type rejects stops the push',
      () {
        const plural = {'1': 'den', '2': 'dny', '5': 'dní', 'other': 'dní'};
        final conflict = _one(local: plural, remote: ('dny', 4));

        final plan = planPush(
          [conflict],
          prefer: Prefer.local,
          remoteKeys: {'k'},
          remoteTypes: {'k': 'text'},
        );
        expect(plan.typeMismatches, [conflict]);
        expect(plan.chunks, isEmpty);

        final edited = _one(local: 'nový', lock: _lock('A'), remote: ('A', 2));
        final other = _one(local: 'B', lock: _lock('A'), remote: ('A', 2));
        final mixed = planPush(
          [edited, other],
          remoteKeys: {'k'},
          remoteTypes: {'k': 'map'},
        );
        expect(mixed.typeMismatches, hasLength(2));
        expect(
          mixed.chunks,
          isEmpty,
          reason: 'nothing is sent when any key mismatches',
        );
      },
    );

    test(
      'plural and map keys take maps, list keys take lists, text keys strings',
      () {
        for (final (type, value) in [
          ('plural', {'one': 'a'}),
          ('map', {'one': 'a'}),
          ('list', ['a']),
          ('text', 'a'),
          ('html', '<b>a</b>'),
        ]) {
          final plan = planPush(
            [_one(local: value, lock: _lock('x'), remote: ('x', 1))],
            remoteKeys: {'k'},
            remoteTypes: {'k': type},
          );
          expect(plan.typeMismatches, isEmpty, reason: type);
          expect(plan.changeCount, 1, reason: type);
        }
      },
    );

    test(
      'chunks at $maxNewKeys new keys; known keys and locales of one key stay together',
      () {
        final diffs = classify(
          local: {
            'cs': {
              for (var i = 0; i < maxNewKeys + 1; i++)
                'k${'$i'.padLeft(4, '0')}': 'v',
            },
            'en': {'k0000': 'v'},
          },
          lock: Lock({}),
          remote: {'cs': {}, 'en': {}},
        );

        final plan = planPush(diffs, remoteKeys: {});
        expect(plan.chunks.map((e) => e.length), [maxNewKeys + 1, 1]);
        expect(
          plan.chunks.first.where((e) => e.key == 'k0000').map((e) => e.locale),
          ['cs', 'en'],
        );

        final known = planPush(
          diffs,
          remoteKeys: diffs.map((e) => e.key).toSet(),
        );
        expect(known.chunks.length, 1);
      },
    );

    test('chunks at $maxChanges changes', () {
      final diffs = classify(
        local: {
          'cs': {for (var i = 0; i < maxChanges + 5; i++) 'k$i': 'v'},
        },
        lock: Lock({}),
        remote: {'cs': {}},
      );
      final keys = diffs.map((e) => e.key).toSet();

      expect(planPush(diffs, remoteKeys: keys).chunks.map((e) => e.length), [
        maxChanges,
        5,
      ]);
    });
  });
}
