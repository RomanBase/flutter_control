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
