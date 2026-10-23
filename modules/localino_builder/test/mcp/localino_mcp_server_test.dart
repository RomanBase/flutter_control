import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:localino_builder/src/config.dart';
import 'package:localino_builder/src/mcp/localino_mcp_server.dart';
import 'package:localino_builder/src/sync/io.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import '../support/fake_localino.dart';

const _cs = 'cs_CZ';
const _en = 'en_US';

/// Secret half of [fakeWriteKey]; must never reach tool output.
final _secret = fakeWriteKey.split('_').last;

final _keyLike = RegExp(
  r'write_?key|api_?key|token|secret|auth|access|password|credential|bearer',
  caseSensitive: false,
);

void main() {
  late Directory root;
  late Map<String, String> env;

  setUp(() {
    root = Directory.systemTemp.createTempSync('localino_mcp');
    env = {
      'HOME': root.path,
      'LOCALINO_API_URL': 'https://api.test/v1',
      writeKeyEnv: fakeWriteKey,
    };
    File('${root.path}/$setupJsonPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'space': 'sp',
          'project': 'pr',
          'access': fakeReadToken,
          'asset': defaultAssetPath,
          'locales': {_cs: '', _en: ''},
        }),
      );
  });

  tearDown(() => root.deleteSync(recursive: true));

  File localeFile(String locale) =>
      File('${root.path}/assets/localization/$locale.json');

  void writeLocal(String locale, Map<String, dynamic> data) =>
      localeFile(locale).writeAsStringSync(
        '${const JsonEncoder.withIndent('    ').convert(data)}\n',
      );

  Map readLocal(String locale) =>
      jsonDecode(localeFile(locale).readAsStringSync()) as Map;

  Future<ServerConnection> connect(http.Client client) async {
    final toServer = StreamController<String>();
    final toClient = StreamController<String>();
    final server = LocalinoMcpServer(
      StreamChannel.withCloseGuarantee(toServer.stream, toClient.sink),
      root: root.path,
      env: env,
      client: client,
    );
    final mcpClient = MCPClient(Implementation(name: 'test', version: '0'));
    final connection = mcpClient.connectServer(
      StreamChannel.withCloseGuarantee(toClient.stream, toServer.sink),
    );

    await connection.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: mcpClient.capabilities,
        clientInfo: mcpClient.implementation,
      ),
    );
    connection.notifyInitialized(InitializedNotification());
    await server.initialized;

    addTearDown(() async {
      await mcpClient.shutdown();
      await server.shutdown();
    });

    return connection;
  }

  Future<CallToolResult> call(
    ServerConnection connection,
    String tool, [
    Map<String, Object?> arguments = const {},
  ]) => connection.callTool(CallToolRequest(name: tool, arguments: arguments));

  Map<String, Object?> data(CallToolResult result) {
    final text = (result.content.single as TextContent).text;
    expect(jsonDecode(text), result.structuredContent);
    return result.structuredContent!;
  }

  group('tools/list', () {
    test('lists the five tools in a fixed order with annotations', () async {
      final connection = await connect(FakeLocalino({}).client);
      final tools = (await connection.listTools()).tools;

      expect(tools.map((e) => e.name), [
        'localino_status',
        'localino_search_keys',
        'localino_set_keys',
        'localino_pull',
        'localino_push',
      ]);
      expect(tools[0].toolAnnotations?.readOnlyHint, true);
      expect(tools[1].toolAnnotations?.readOnlyHint, true);
      expect(tools[2].toolAnnotations?.destructiveHint, false);
      expect(tools[2].toolAnnotations?.idempotentHint, true);
      expect(tools[3].toolAnnotations?.openWorldHint, true);
      expect(tools[4].toolAnnotations?.destructiveHint, true);
      expect(tools[4].toolAnnotations?.openWorldHint, true);
    });

    test('no input schema has a key-like property', () async {
      final connection = await connect(FakeLocalino({}).client);
      final names = <String>[];

      void collect(Object? schema) {
        if (schema is! Map) return;
        final properties = schema['properties'];
        if (properties is Map) {
          for (final entry in properties.entries) {
            names.add('${entry.key}');
            collect(entry.value);
          }
        }
        collect(schema['items']);
      }

      for (final tool in (await connection.listTools()).tools) {
        collect(tool.inputSchema);
      }

      expect(names, isNotEmpty);
      expect(names.where(_keyLike.hasMatch), isEmpty);
    });
  });

  group('localino_push', () {
    test('defaults to a dry run and applies only with dry_run false', () async {
      writeLocal(_cs, {'invoice_paid': 'Zaplaceno'});
      writeLocal(_en, {});
      final fake = FakeLocalino({_cs: {}, _en: {}});
      final connection = await connect(fake.client);

      final plan = data(await call(connection, 'localino_push'));

      expect(plan['dry_run'], true);
      expect(plan['pushed'], [
        {'locale': _cs, 'key': 'invoice_paid', 'ts': null},
      ]);
      expect(plan['next_step'], contains('dry_run: false'));
      expect(jsonDecode(fake.pushes.single.body)['dry_run'], true);
      expect(fake.translations[_cs], isEmpty);
      expect(File('${root.path}/$lockPath').existsSync(), false);

      final applied = data(
        await call(connection, 'localino_push', {'dry_run': false}),
      );

      expect(applied['dry_run'], false);
      expect(fake.translations[_cs]!['invoice_paid']!.$1, 'Zaplaceno');
      expect(File('${root.path}/$lockPath').existsSync(), true);
    });

    test('lists conflicts and asks the user instead of writing', () async {
      writeLocal(_cs, {'a': 'local'});
      writeLocal(_en, {});
      final fake = FakeLocalino({
        _cs: {'a': ('remote', 5)},
        _en: {},
      });
      final connection = await connect(fake.client);

      final result = data(
        await call(connection, 'localino_push', {'dry_run': false}),
      );

      expect(result['conflicts'], hasLength(1));
      expect(result['next_step'], contains('ask which side wins'));
      expect(fake.pushes, isEmpty);
      expect(fake.translations[_cs]!['a']!.$1, 'remote');
    });

    test('a key Localino types differently is reported, not pushed', () async {
      writeLocal(_cs, {
        'days': {'one': 'den', 'other': 'dní'},
      });
      writeLocal(_en, {});
      final fake = FakeLocalino({
        _cs: {'days': ('dny', 5)},
        _en: {},
      });
      final connection = await connect(fake.client);

      final result = data(
        await call(connection, 'localino_push', {
          'dry_run': false,
          'prefer': 'local',
        }),
      );

      expect(result['type_mismatches'], [containsPair('remote_type', 'text')]);
      expect(result['next_step'], contains('Localino console'));
      expect(fake.pushes, isEmpty);
    });

    test('keys or values Localino rejects are reported, not pushed', () async {
      writeLocal(_cs, {'bad key': 'x'});
      writeLocal(_en, {});
      final fake = FakeLocalino({_cs: {}, _en: {}});
      final connection = await connect(fake.client);

      final result = data(await call(connection, 'localino_push'));

      expect(result['invalid'], [
        {'locale': _cs, 'key': 'bad key', 'reason': 'invalid_key'},
      ]);
      expect(result['next_step'], contains('not accepted by Localino'));
      expect(fake.pushes, isEmpty);
    });

    test('missing write key is an error with zero requests', () async {
      env.remove(writeKeyEnv);
      writeLocal(_cs, {'a': 'A'});
      final fake = FakeLocalino({_cs: {}});
      final connection = await connect(fake.client);

      final result = await call(connection, 'localino_push');

      expect(result.isError, true);
      expect(data(result)['next_step'], contains('login'));
      expect(fake.requests, isEmpty);
    });
  });

  test('the write key appears in no tool output', () async {
    writeLocal(_cs, {'a': 'A', 'b': 'B'});
    writeLocal(_en, {'a': 'A'});
    final fake = FakeLocalino({
      _cs: {'b': ('remote', 5)},
      _en: {},
    });
    final connection = await connect(fake.client);
    final outputs = <CallToolResult>[
      await call(connection, 'localino_status'),
      await call(connection, 'localino_search_keys', {'query': 'a'}),
      await call(connection, 'localino_set_keys', {
        'keys': [
          {
            'key': 'c',
            'values': {_cs: 'C'},
          },
        ],
      }),
      await call(connection, 'localino_set_keys', {
        'keys': [
          {
            'key': 'bad',
            'values': {'xx_XX': 'X'},
          },
        ],
      }),
      await call(connection, 'localino_pull'),
      // 409 conflict on `b`.
      await call(connection, 'localino_push', {'dry_run': false}),
    ];

    fake.pushResponses[fake.pushes.length] = FakeLocalino.json(401, {
      'error': 'unauthorized',
    });
    outputs.add(await call(connection, 'localino_push', {'prefer': 'local'}));

    fake.pushResponses[fake.pushes.length] = FakeLocalino.json(422, {
      'error': 'invalid',
      'details': [
        {'key': fakeWriteKey, 'reason': 'echoed'},
      ],
    });
    outputs.add(await call(connection, 'localino_push', {'prefer': 'local'}));

    env.remove(writeKeyEnv);
    outputs.add(await call(connection, 'localino_push'));

    expect(outputs.where((e) => e.isError == true), hasLength(4));
    expect(
      fake.pushes.map((e) => e.headers['authorization']),
      everyElement('Bearer $fakeWriteKey'),
    );

    for (final output in outputs) {
      final text = [
        for (final content in output.content) (content as TextContent).text,
        jsonEncode(output.structuredContent),
      ].join('\n');

      expect(text, isNot(contains(_secret)));
      expect(text, isNot(contains(fakeWriteKey)));
    }
  });

  group('localino_set_keys', () {
    test('writes local files only, keeping order and indent', () async {
      writeLocal(_cs, {'z': 'Z', 'a': 'A'});
      writeLocal(_en, {'z': 'Z'});
      final fake = FakeLocalino({_cs: {}, _en: {}});
      final connection = await connect(fake.client);

      final result = data(
        await call(connection, 'localino_set_keys', {
          'keys': [
            {
              'key': 'invoice_paid',
              'values': {_cs: 'Zaplaceno'},
            },
            {
              'key': 'plural',
              'values': {
                _cs: {'one': 'x', 'other': 'y'},
              },
            },
            {
              'key': 'a',
              'values': {_cs: 'A2'},
            },
          ],
          'remove': ['z'],
        }),
      );

      expect(result['changed'], true);
      expect(result['diff'], [
        {
          'locale': _cs,
          'key': 'invoice_paid',
          'change': 'added',
          'new': 'Zaplaceno',
        },
        {
          'locale': _cs,
          'key': 'plural',
          'change': 'added',
          'new': {'one': 'x', 'other': 'y'},
        },
        {
          'locale': _cs,
          'key': 'a',
          'change': 'updated',
          'old': 'A',
          'new': 'A2',
        },
        {'locale': _cs, 'key': 'z', 'change': 'removed', 'old': 'Z'},
        {'locale': _en, 'key': 'z', 'change': 'removed', 'old': 'Z'},
      ]);
      expect(result['incomplete'], [
        {
          'key': 'invoice_paid',
          'missing_in': [_en],
        },
        {
          'key': 'plural',
          'missing_in': [_en],
        },
        {
          'key': 'a',
          'missing_in': [_en],
        },
      ]);
      expect(result['next_step'], contains('codegen'));
      expect(readLocal(_cs).keys, ['a', 'invoice_paid', 'plural']);
      expect(localeFile(_cs).readAsStringSync(), contains('\n    "a": "A2"'));
      expect(fake.requests, isEmpty);
    });

    test('is idempotent', () async {
      writeLocal(_cs, {'a': 'A'});
      writeLocal(_en, {'a': 'A'});
      final connection = await connect(FakeLocalino({}).client);
      final arguments = {
        'keys': [
          {
            'key': 'b',
            'values': {_cs: 'B', _en: 'B'},
          },
        ],
      };

      await call(connection, 'localino_set_keys', arguments);
      final bytes = localeFile(_cs).readAsStringSync();
      final second = data(
        await call(connection, 'localino_set_keys', arguments),
      );

      expect(second['changed'], false);
      expect(second['diff'], isEmpty);
      expect(localeFile(_cs).readAsStringSync(), bytes);
    });

    test('rejects unknown locales and invalid keys without writing', () async {
      writeLocal(_cs, {'a': 'A'});
      final before = localeFile(_cs).readAsStringSync();
      final connection = await connect(FakeLocalino({}).client);

      final result = await call(connection, 'localino_set_keys', {
        'keys': [
          {
            'key': 'b',
            'values': {_cs: 'B', 'de_DE': 'B'},
          },
          {
            'key': 'bad key',
            'values': {_cs: 'X'},
          },
        ],
      });

      expect(result.isError, true);
      expect(data(result)['error'], contains('unknown locale `de_DE`'));
      expect(data(result)['error'], contains('`bad key`: invalid key'));
      expect(localeFile(_cs).readAsStringSync(), before);
    });

    test('rejects input that does not match the schema', () async {
      writeLocal(_cs, {});
      final connection = await connect(FakeLocalino({}).client);

      final result = await call(connection, 'localino_set_keys', {
        'keys': [
          {'key': 'a'},
        ],
      });

      expect(result.isError, true);
    });

    test('regenerates localino_keys.dart when generate_keys is on', () async {
      File('${root.path}/build.yaml').writeAsStringSync('''
targets:
  \$default:
    builders:
      localino_builder:
        options:
          space: sp
          project: pr
          access: $fakeReadToken
          generate_keys: true
''');
      writeLocal(_cs, {'a': 'A'});
      final connection = await connect(FakeLocalino({}).client);

      final result = data(
        await call(connection, 'localino_set_keys', {
          'keys': [
            {
              'key': 'invoice_paid',
              'values': {_cs: 'Zaplaceno'},
            },
          ],
        }),
      );

      expect(result['generated_keys'], 'lib/generated/localino_keys.dart');
      expect(
        File(
          '${root.path}/lib/generated/localino_keys.dart',
        ).readAsStringSync(),
        contains('invoice_paid'),
      );
    });
  });

  group('localino_search_keys', () {
    test('local tools work even with an unusable LOCALINO_API_URL', () async {
      writeLocal(_cs, {'a': 'A'});
      env['LOCALINO_API_URL'] = 'http://example.com/v1';
      final connection = await connect(FakeLocalino({}).client);

      final search = await call(connection, 'localino_search_keys', {
        'query': 'a',
      });
      final set = await call(connection, 'localino_set_keys', {
        'keys': [
          {
            'key': 'b',
            'values': {_cs: 'B'},
          },
        ],
      });

      expect(search.isError, isNot(true));
      expect(set.isError, isNot(true));
      expect(readLocal(_cs), {'a': 'A', 'b': 'B'});
    });

    setUp(() {
      writeLocal(_cs, {
        'invoice_paid': 'Zaplaceno',
        'order_paid': 'Zaplaceno',
        'invoice_due': 'Splatné',
        'empty_cs': '',
      });
      writeLocal(_en, {
        'invoice_paid': 'Paid',
        'invoice_due': 'Due',
        'empty_cs': 'Empty',
      });
    });

    test('matches keys and values, exact values first', () async {
      final connection = await connect(FakeLocalino({}).client);

      final result = data(
        await call(connection, 'localino_search_keys', {'query': 'zaplaceno'}),
      );

      expect(result['total'], 2);
      expect(result['matches'], [
        {
          'key': 'invoice_paid',
          'values': {_cs: 'Zaplaceno', _en: 'Paid'},
          'exact_value_match': true,
          'same_value_as': ['order_paid'],
        },
        {
          'key': 'order_paid',
          'values': {_cs: 'Zaplaceno'},
          'exact_value_match': true,
          'same_value_as': ['invoice_paid'],
        },
      ]);
      expect(result['next_step'], contains('reuse'));
    });

    test('finds keys missing or empty in a locale', () async {
      final connection = await connect(FakeLocalino({}).client);

      final missingEn = data(
        await call(connection, 'localino_search_keys', {'missing_in': _en}),
      );
      final missingCs = data(
        await call(connection, 'localino_search_keys', {'missing_in': _cs}),
      );

      expect((missingEn['matches'] as List).map((e) => (e as Map)['key']), [
        'order_paid',
      ]);
      expect((missingCs['matches'] as List).map((e) => (e as Map)['key']), [
        'empty_cs',
      ]);
    });

    test('looks up exact keys and reports unknown ones', () async {
      final connection = await connect(FakeLocalino({}).client);

      final result = data(
        await call(connection, 'localino_search_keys', {
          'keys': ['invoice_due', 'nope'],
          'limit': 1,
        }),
      );

      expect((result['matches'] as List).map((e) => (e as Map)['key']), [
        'invoice_due',
      ]);
      expect(result['not_found'], ['nope']);
    });

    test('caps results at limit', () async {
      final connection = await connect(FakeLocalino({}).client);

      final result = data(
        await call(connection, 'localino_search_keys', {'limit': 1}),
      );

      expect(result['total'], 4);
      expect(result['matches'], hasLength(1));
      expect(result['truncated'], true);
    });

    test('rejects an unknown locale', () async {
      final connection = await connect(FakeLocalino({}).client);

      final result = await call(connection, 'localino_search_keys', {
        'missing_in': 'de_DE',
      });

      expect(result.isError, true);
    });
  });

  group('localino_status', () {
    test('reports changes and points at pull/push', () async {
      writeLocal(_cs, {'local_new': 'L', 'same': 'S'});
      final fake = FakeLocalino({
        _cs: {'remote_new': ('R', 3), 'same': ('S', 2)},
      });
      final connection = await connect(fake.client);

      final result = data(await call(connection, 'localino_status'));

      expect(result['remote_known'], true);
      expect((result['counts'] as Map)['localChanged'], 1);
      expect((result['counts'] as Map)['remoteChanged'], 1);
      expect(result['next_step'], contains('localino_pull'));
      expect(result['next_step'], contains('localino_push'));
      expect((result['counts'] as Map)['converged'], 1);
      expect(result['next_step'], contains('records them in the lock'));
    });

    test('offline compares local files with the lock only', () async {
      writeLocal(_cs, {'a': 'A'});
      final client = MockClient((_) => throw const SocketException('offline'));
      final connection = await connect(client);

      final result = await call(connection, 'localino_status');

      expect(result.isError, isNot(true));
      expect(data(result)['remote_known'], false);
      expect(data(result)['next_step'], contains('unreachable'));
    });

    test('caps the changes list at limit', () async {
      writeLocal(_cs, {'a': 'A', 'b': 'B', 'c': 'C'});
      final connection = await connect(FakeLocalino({_cs: {}}).client);

      final result = data(
        await call(connection, 'localino_status', {'limit': 2}),
      );

      expect(result['changes'], hasLength(2));
      expect(result['truncated'], {'changes': 3});
    });
  });

  group('localino_pull', () {
    test('leaves conflicts untouched unless prefer is given', () async {
      writeLocal(_cs, {'a': 'local'});
      final fake = FakeLocalino({
        _cs: {'a': ('remote', 5), 'b': ('B', 6)},
      });
      final connection = await connect(fake.client);

      final stopped = data(await call(connection, 'localino_pull'));

      expect(stopped['conflicts'], hasLength(1));
      expect(readLocal(_cs), {'a': 'local'});

      final resolved = data(
        await call(connection, 'localino_pull', {
          'prefer': 'remote',
          'keys': ['a'],
        }),
      );

      expect(resolved['conflicts'], isEmpty);
      expect(resolved['next_step'], contains('codegen'));
      expect(readLocal(_cs), {'a': 'remote'});
    });

    test('rejects an invalid prefer value', () async {
      writeLocal(_cs, {});
      final connection = await connect(FakeLocalino({_cs: {}}).client);

      final result = await call(connection, 'localino_pull', {
        'prefer': 'mine',
      });

      expect(result.isError, true);
    });
  });
}
