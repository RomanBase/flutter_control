## [1.2.1]
- A local value whose shape the key's Localino type rejects (e.g. a plural map where Localino has text) is reported as `type_mismatches` and stops `push`/`sync` with exit 3 before anything is written. `sync` used to pull first and then fail the push with exit 5 ("re-run `sync`"), which could never succeed.
- `sync` keeps the push's exit code when the push fails after a pull (e.g. 4 for a revoked key) instead of reporting every failure as 5.

## [1.2.0]
- Bidirectional sync: `dart run localino_builder status | pull | push | sync | login`. Three-way merge by value hash against a committed `.localino/lock.json`; pull never drops local-only keys, push never deletes remotely without `--prune`, conflicts stop the run (exit 3) until resolved with `--prefer local|remote`.
- Push uses a per-project write key (`login` reads it from stdin into `~/.localino/credentials.json`, mode 600; `LOCALINO_WRITE_KEY` overrides). The shared read token is never used for writes.
- `LOCALINO_API_URL` overrides the API base; plain http is refused except for localhost.
- MCP server for coding agents: `dart run localino_builder:mcp` (stdio) with `localino_status`, `localino_search_keys`, `localino_set_keys`, `localino_pull` and `localino_push` (dry run by default). The write key is read in-process and never appears in tool input or output.
- Config: `build.yaml` with `localino_builder|localino_builder` keys or `enabled: false` now falls back to `assets/localization/setup.json`.
- The builder no longer prints the access token.
- **Requires Dart 3.7+.** Needs the `snapshot` / `push` routes of Localino API v1 (13).

## [1.1.0]
- Typed key generator (opt-in via `generate_keys`): emits `lib/generated/localino_keys.dart` with a `LocalinoKeys` const per JSON key for compile-time-safe lookups. Const values are the original JSON keys verbatim — runtime unchanged.
- Doc comments carry default-locale preview, `params:` for format strings, and `⚠ missing in:` for keys absent in other locales.
- Optional unused-key reporter (`report_unused`): lists keys with no `LocalinoKeys.<name>` reference under `lib/` (report-only, never deletes).
- CLI flags `--generate-keys` / `--report-unused` for the standalone binary.
- Additive and non-breaking: defaults keep existing behavior.

## [1.0.1]
- CLI implementation: dart run localino_builder -u {token} -sp {space:project}

## [1.0.0]
- Builder for [localino] that downloads localization files via API
