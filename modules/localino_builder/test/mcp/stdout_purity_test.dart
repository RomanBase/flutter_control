import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:localino_builder/src/config.dart';
import 'package:localino_builder/src/sync/io.dart';
import 'package:test/test.dart';

import '../support/fake_localino.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('localino_mcp_stdio');
    File('${root.path}/$setupJsonPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'space': 'sp',
          'project': 'pr',
          'access': fakeReadToken,
          'locales': {'cs_CZ': ''},
        }),
      );
    File(
      '${root.path}/assets/localization/cs_CZ.json',
    ).writeAsStringSync('{\n  "a": "A"\n}\n');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('stdout carries only JSON-RPC', () async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', 'bin/mcp.dart', '--root', root.path],
      environment: {
        'HOME': root.path,
        // Nothing listens on the discard port: remote calls fail fast.
        'LOCALINO_API_URL': 'http://127.0.0.1:9/v1',
        writeKeyEnv: fakeWriteKey,
      },
    );
    final lines = <String>[];
    final responses = <int, Map>{};
    final pending = <int, Completer<Map>>{};

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          lines.add(line);
          final message = jsonDecode(line) as Map;
          final id = message['id'];
          if (id is int) {
            responses[id] = message;
            pending.remove(id)?.complete(message);
          }
        });
    final stderrDone = process.stderr.drain<void>();

    Future<Map> send(int id, String method, Map params) {
      final completer = pending[id] = Completer<Map>();
      process.stdin.writeln(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'method': method,
          'params': params,
        }),
      );
      return completer.future;
    }

    await send(1, 'initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': {},
      'clientInfo': {'name': 'purity', 'version': '0'},
    });
    process.stdin.writeln(
      jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'}),
    );
    final list = await send(2, 'tools/list', {});
    await send(3, 'tools/call', {'name': 'localino_status', 'arguments': {}});
    await send(4, 'tools/call', {
      'name': 'localino_set_keys',
      'arguments': {
        'keys': [
          {
            'key': 'b',
            'values': {'cs_CZ': 'B'},
          },
        ],
      },
    });
    await send(5, 'tools/call', {'name': 'localino_push', 'arguments': {}});

    await process.stdin.close();
    expect(await process.exitCode, 0);
    await stderrDone;

    expect((list['result']['tools'] as List), hasLength(5));
    expect(responses.keys, [1, 2, 3, 4, 5]);
    expect(lines, isNotEmpty);
    for (final line in lines) {
      expect(jsonDecode(line), containsPair('jsonrpc', '2.0'));
      expect(line, isNot(contains(fakeWriteKey.split('_').last)));
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
