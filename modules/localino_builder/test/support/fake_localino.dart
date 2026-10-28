import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:localino_builder/src/sync/merge.dart';

const fakeReadToken = 'read-token';
const fakeWriteKey =
    'lk_w_AbCdEf123456_0123456789abcdefghijABCDEFGHIJklmnopqrstuvw';

/// In-memory Localino implementing the snapshot / push contract.
class FakeLocalino {
  final Map<String, Map<String, (dynamic, int)>> translations;
  final Set<String> locked;
  final requests = <http.Request>[];

  /// Overrides the push response for the n-th push call (0-based).
  final Map<int, http.Response> pushResponses = {};
  int _pushes = 0;
  int _ts = 1000;

  FakeLocalino(this.translations, {this.locked = const {}});

  MockClient get client => MockClient((request) async {
    requests.add(request);

    if (request.url.path.endsWith('/snapshot')) {
      if (request.headers['access'] != fakeReadToken) {
        return http.Response('unauthorized', 401);
      }
      return json(200, _snapshot());
    }

    if (request.url.path.endsWith('/locales')) {
      if (request.headers['authorization'] != 'Bearer $fakeWriteKey') {
        return json(401, {'error': 'unauthorized'});
      }
      final body = jsonDecode(request.body) as Map;
      final locales = [
        for (final item in body['locales'] as List) '${item['locale']}',
      ];
      final added = locales.where((e) => !translations.containsKey(e)).toList();
      if (body['dry_run'] != true) {
        for (final locale in added) {
          translations[locale] = {};
        }
      }
      return json(200, {
        'dry_run': body['dry_run'] == true,
        'added': added,
        'existing': locales.where((e) => !added.contains(e)).toList(),
      });
    }

    if (request.url.path.endsWith('/push')) {
      final override = pushResponses[_pushes++];
      if (override != null) return override;
      if (request.headers['authorization'] != 'Bearer $fakeWriteKey') {
        return json(401, {'error': 'unauthorized'});
      }
      return _push(jsonDecode(request.body) as Map);
    }

    return http.Response('not found', 404);
  });

  List<http.Request> get localeRequests =>
      requests.where((e) => e.url.path.endsWith('/locales')).toList();

  List<http.Request> get pushes =>
      requests.where((e) => e.url.path.endsWith('/push')).toList();

  Map<String, dynamic> _snapshot() => {
    'locales': translations.keys.toList(),
    'keys': {
      for (final locale in translations.values)
        for (final MapEntry(:key, :value) in locale.entries)
          key: {
            'type': switch (value.$1) {
              List() => 'list',
              Map() => 'map',
              _ => 'text',
            },
            'locked': locked.contains(key),
          },
    },
    'translations': {
      for (final locale in translations.entries)
        locale.key: {
          for (final entry in locale.value.entries)
            entry.key: {'value': entry.value.$1, 'ts': entry.value.$2},
        },
    },
  };

  http.Response _push(Map body) {
    final dryRun = body['dry_run'] == true;
    final changes = List<Map>.from(body['changes'] as List);
    final conflicts = <Map>[];
    final applied = <Map>[];
    final unchanged = <Map>[];
    final rejected = <Map>[];

    for (final change in changes) {
      final remote = translations[change['locale']]?[change['key']];

      if (locked.contains(change['key'])) {
        rejected.add({'locale': change['locale'], 'key': change['key']});
      } else if (change['delete'] == true
          ? remote == null
          : remote != null &&
              canonicalJson(remote.$1) == canonicalJson(change['value'])) {
        // Same value (or deleting an absent key) is a no-op, as in the API.
        unchanged.add({
          'locale': change['locale'],
          'key': change['key'],
          'ts': remote?.$2,
        });
      } else if (change['base_ts'] != remote?.$2) {
        conflicts.add({
          'locale': change['locale'],
          'key': change['key'],
          'base_ts': change['base_ts'],
          'remote_ts': remote?.$2,
        });
      } else {
        applied.add(change);
      }
    }

    if (conflicts.isNotEmpty) {
      return json(409, {'error': 'conflict', 'conflicts': conflicts});
    }

    final ts = dryRun ? null : _ts++;

    if (!dryRun) {
      for (final change in applied) {
        final locale = translations[change['locale']]!;
        if (change['delete'] == true) {
          locale.remove(change['key']);
        } else {
          locale[change['key']] = (change['value'], ts!);
        }
      }
    }

    return json(200, {
      'dry_run': dryRun,
      'applied': [
        for (final change in applied)
          {'locale': change['locale'], 'key': change['key'], 'ts': ts},
      ],
      'unchanged': unchanged,
      'rejected_locked': rejected,
    });
  }

  static http.Response json(int status, Map body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
