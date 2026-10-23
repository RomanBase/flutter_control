import 'dart:async';
import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:http/http.dart' as http;
import 'package:localino_builder/src/config.dart';
import 'package:localino_builder/src/mcp/localino_mcp_server.dart';

/// Localino MCP server over stdio: `dart run localino_builder:mcp [--root <dir>]`.
/// stdout carries only JSON-RPC, so `print` is routed to stderr.
void main(List<String> arguments) {
  runZoned(
    () async {
      final rootArg = arguments.indexOf('--root');
      final root =
          rootArg >= 0 && rootArg + 1 < arguments.length
              ? arguments[rootArg + 1]
              : findProjectRoot(Directory.current.path);
      final client = http.Client();

      final server = LocalinoMcpServer(
        stdioChannel(input: stdin, output: stdout),
        root: root,
        env: Platform.environment,
        client: client,
      );

      await server.done;
      client.close();
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => stderr.writeln(line),
    ),
  );
}
