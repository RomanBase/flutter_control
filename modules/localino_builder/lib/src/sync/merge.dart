import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Changes allowed per push request (server cap).
const maxChanges = 2000;

/// Keys not yet in Localino per push request (server cap; Firestore commits ≤ 500 writes).
const maxNewKeys = 400;

/// JSON with map keys sorted recursively, so equal values compare equal as strings.
String canonicalJson(dynamic value) => jsonEncode(_canonical(value));

dynamic _canonical(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((e) => '$e').toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }

  if (value is List) {
    return value.map(_canonical).toList();
  }

  return value;
}

/// Short value hash stored in the lock: first 16 hex chars of sha256(canonical JSON).
String valueHash(dynamic value) => sha256
    .convert(utf8.encode(canonicalJson(value)))
    .toString()
    .substring(0, 16);

/// Last-synced state of one key: value hash + server timestamp (epoch ms).
class LockEntry {
  final String h;
  final int ts;

  const LockEntry(this.h, this.ts);

  @override
  bool operator ==(Object other) =>
      other is LockEntry && other.h == h && other.ts == ts;

  @override
  int get hashCode => Object.hash(h, ts);

  @override
  String toString() => 'LockEntry($h, $ts)';
}

/// `.localino/lock.json` content: locale → key → [LockEntry].
class Lock {
  final Map<String, Map<String, LockEntry>> locales;

  Lock(this.locales);

  LockEntry? entry(String locale, String key) => locales[locale]?[key];

  void set(String locale, String key, LockEntry? entry) {
    if (entry == null) {
      locales[locale]?.remove(key);
    } else {
      (locales[locale] ??= {})[key] = entry;
    }
  }

  /// Records the remote side of [diff] as the new baseline.
  void acceptRemote(KeyDiff diff) => set(
    diff.locale,
    diff.key,
    diff.remote == null
        ? null
        : LockEntry(valueHash(diff.remote!.value), diff.remote!.ts),
  );
}

/// A remote translation from the snapshot.
class RemoteEntry {
  final dynamic value;
  final int ts;

  const RemoteEntry(this.value, this.ts);
}

enum KeyState { unchanged, localChanged, remoteChanged, converged, conflict }

enum Prefer { local, remote }

Prefer? parsePrefer(String? value) => switch (value) {
  'local' => Prefer.local,
  'remote' => Prefer.remote,
  _ => null,
};

class KeyDiff {
  final String locale;
  final String key;
  final KeyState state;

  /// Local value, null when absent.
  final dynamic local;

  /// Remote entry, null when absent (or when the remote is unknown).
  final RemoteEntry? remote;
  final LockEntry? lock;

  const KeyDiff(
    this.locale,
    this.key,
    this.state, {
    this.local,
    this.remote,
    this.lock,
  });

  /// The changed side added the key (no baseline).
  bool get added =>
      lock == null &&
      (state == KeyState.localChanged || state == KeyState.remoteChanged);

  /// The changed side removed the key.
  bool get deleted =>
      (state == KeyState.localChanged && local == null) ||
      (state == KeyState.remoteChanged && remote == null);

  Map<String, dynamic> toJson() => {
    'locale': locale,
    'key': key,
    'state': state.name,
    if (added) 'added': true,
    if (deleted) 'deleted': true,
  };

  @override
  String toString() =>
      'KeyDiff($locale/$key: ${state.name}${added ? ' added' : ''}${deleted ? ' deleted' : ''})';
}

/// Three-way classification of every key in [local] (and [remote]) against [lock], by
/// value hash. Locales come from [local] and [remote]; pass a remote of null when offline
/// — keys then compare local vs lock only.
List<KeyDiff> classify({
  required Map<String, Map<String, dynamic>> local,
  required Lock lock,
  Map<String, Map<String, RemoteEntry>>? remote,
}) {
  final diffs = <KeyDiff>[];
  final locales = {...local.keys, ...?remote?.keys}.toList()..sort();

  for (final locale in locales) {
    final localKeys = local[locale] ?? const {};
    final remoteKeys = remote?[locale] ?? const <String, RemoteEntry>{};
    final keys =
        {
            ...localKeys.keys,
            ...remoteKeys.keys,
            ...?lock.locales[locale]?.keys,
          }.toList()
          ..sort();

    for (final key in keys) {
      final l = localKeys[key];
      final r = remoteKeys[key];
      final b = lock.entry(locale, key);

      final lh = l == null ? null : valueHash(l);
      final rh =
          remote == null ? b?.h : (r == null ? null : valueHash(r.value));
      final bh = b?.h;

      final KeyState state;

      if (lh == bh && rh == bh) {
        state = KeyState.unchanged;
      } else if (rh == bh) {
        state = KeyState.localChanged;
      } else if (lh == bh) {
        state = KeyState.remoteChanged;
      } else if (lh == rh) {
        state = KeyState.converged;
      } else {
        state = KeyState.conflict;
      }

      diffs.add(KeyDiff(locale, key, state, local: l, remote: r, lock: b));
    }
  }

  return diffs;
}

Map<KeyState, int> countStates(Iterable<KeyDiff> diffs) {
  final counts = {for (final state in KeyState.values) state: 0};

  for (final diff in diffs) {
    counts[diff.state] = counts[diff.state]! + 1;
  }

  return counts;
}

class PullPlan {
  /// Diffs whose remote value replaces the local one (set, or remove when absent).
  final List<KeyDiff> updates;

  /// Diffs that only move the lock to the remote baseline (converged, re-stamped).
  final List<KeyDiff> baseline;

  /// Unresolved conflicts — the run stops and nothing is written.
  final List<KeyDiff> conflicts;

  const PullPlan({
    this.updates = const [],
    this.baseline = const [],
    this.conflicts = const [],
  });
}

/// Plans a pull. Local-only changes are never touched; conflicts take the remote side
/// only with `prefer: remote` and are left alone with `prefer: local`.
PullPlan planPull(List<KeyDiff> diffs, {Prefer? prefer}) {
  final updates = <KeyDiff>[];
  final baseline = <KeyDiff>[];
  final conflicts = <KeyDiff>[];

  for (final diff in diffs) {
    switch (diff.state) {
      case KeyState.remoteChanged:
        updates.add(diff);
      case KeyState.converged:
        baseline.add(diff);
      case KeyState.unchanged:
        if (diff.remote != null &&
            diff.lock != null &&
            diff.remote!.ts != diff.lock!.ts) {
          baseline.add(diff);
        }
      case KeyState.conflict:
        if (prefer == Prefer.remote) {
          updates.add(diff);
        } else if (prefer == null) {
          conflicts.add(diff);
        }
      case KeyState.localChanged:
        break;
    }
  }

  return PullPlan(updates: updates, baseline: baseline, conflicts: conflicts);
}

class PushChange {
  final String locale;
  final String key;
  final dynamic value;
  final bool delete;

  /// Remote timestamp the change was planned against; null = remote absent.
  final int? baseTs;

  const PushChange({
    required this.locale,
    required this.key,
    this.value,
    this.delete = false,
    this.baseTs,
  });

  Map<String, dynamic> toJson() => {
    'locale': locale,
    'key': key,
    if (delete) 'delete': true else 'value': value,
    'base_ts': baseTs,
  };
}

class PushPlan {
  /// Request bodies, each within [maxChanges] and [maxNewKeys].
  final List<List<PushChange>> chunks;

  /// Local deletions not sent because `--prune` was not given.
  final List<KeyDiff> skippedDeletes;

  /// Unresolved conflicts — the run stops and nothing is sent.
  final List<KeyDiff> conflicts;

  const PushPlan({
    this.chunks = const [],
    this.skippedDeletes = const [],
    this.conflicts = const [],
  });

  int get changeCount => chunks.fold(0, (sum, chunk) => sum + chunk.length);
}

/// Plans a push of local changes (and conflicts with `prefer: local`). Deletes are sent
/// only with [prune]. [remoteKeys] are the keys Localino already knows (for chunking).
PushPlan planPush(
  List<KeyDiff> diffs, {
  Prefer? prefer,
  bool prune = false,
  required Set<String> remoteKeys,
}) {
  final byKey = <String, List<PushChange>>{};
  final skippedDeletes = <KeyDiff>[];
  final conflicts = <KeyDiff>[];

  for (final diff in diffs) {
    if (diff.state == KeyState.conflict) {
      if (prefer == null) {
        conflicts.add(diff);
        continue;
      }

      if (prefer == Prefer.remote) continue;
    } else if (diff.state != KeyState.localChanged) {
      continue;
    }

    if (diff.local == null) {
      if (diff.remote == null) continue;

      if (!prune) {
        skippedDeletes.add(diff);
        continue;
      }
    }

    (byKey[diff.key] ??= []).add(
      PushChange(
        locale: diff.locale,
        key: diff.key,
        value: diff.local,
        delete: diff.local == null,
        baseTs: diff.remote?.ts,
      ),
    );
  }

  final chunks = <List<PushChange>>[];
  var chunk = <PushChange>[];
  var newKeys = 0;

  for (final key in byKey.keys.toList()..sort()) {
    final changes = byKey[key]!;
    final isNew = !remoteKeys.contains(key) && changes.any((e) => !e.delete);

    if (chunk.isNotEmpty &&
        (chunk.length + changes.length > maxChanges ||
            (isNew && newKeys >= maxNewKeys))) {
      chunks.add(chunk);
      chunk = [];
      newKeys = 0;
    }

    chunk.addAll(changes);
    if (isNew) newKeys++;
  }

  if (chunk.isNotEmpty) chunks.add(chunk);

  return PushPlan(
    chunks: conflicts.isEmpty ? chunks : const [],
    skippedDeletes: skippedDeletes,
    conflicts: conflicts,
  );
}
