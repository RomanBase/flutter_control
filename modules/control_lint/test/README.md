# Tests

Two tiers of coverage:

1. **`wrap_assist_test.dart`** (automated) — asserts the exact wrap output for
   every assist: the `opening()` / `closing` insertion strings, the seeded
   `control:` / `controls:` arguments, the builder-callback parameter names, the
   prefixed-widget reference (`fc.ControlBuilder`), and the `AssistKind`
   metadata. Run: `dart test`.

2. **Live smoke test** (manual, see `../example/`) — the actual assist rendering
   and node resolution in VS Code / IntelliJ. This is what confirms the plugin
   loads and the lightbulb offers the assist on a real widget.

## Known gap

There is no automated **resolved-AST** test that drives the full `PluginServer`
against a Flutter-resolved unit (the tier that would catch a `targetWidget`
node-selection regression automatically). `parseString` is unresolved, so it
parses `Center(...)` as a `MethodInvocation` rather than an
`InstanceCreationExpression` — it cannot exercise the widget-type gate or node
walk faithfully. A follow-up should adopt a resolved harness (cf. riverpod_lint's
`@TestFor` golden runner) with a real Flutter SDK. Until then, node resolution is
covered by the manual smoke test.
