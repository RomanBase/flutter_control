# Tests

Two tiers of coverage:

1. **Automated** (`dart test`):
   - `wrap_assist_test.dart` — the exact wrap output for every assist: the
     `opening()` / `closing` insertion strings, the seeded `control:` /
     `controls:` arguments, the builder-callback parameter names, the
     prefixed-widget reference (`fc.ControlBuilder`), and the `AssistKind`
     metadata.
   - `target_widget_test.dart` — `targetWidget`'s cursor-walk / nested-widget
     logic (the unit that regressed in the spike), driven by `parseString` with
     explicit `new Foo(...)` so the unresolved parser yields
     `InstanceCreationExpression`. Plus `isFlutterWidget`'s `null` guard.

2. **Live smoke test** (manual, see `../example/`) — the assist rendering + apply
   in VS Code / IntelliJ. Confirms the plugin actually loads.

## Known gap

`isFlutterWidget`'s **positive** path (walking supertypes to find Flutter's
`Widget`) is not automatically tested: it reads `constructorName.type.type`,
which is `null` on an unresolved AST, so `parseString` can't exercise it — it
needs a real Flutter SDK. The full end-to-end assist (node → type gate → edit →
import) is likewise only covered by the manual smoke test.

A follow-up should adopt a **resolved-AST** harness that drives the real
`PluginServer` against a Flutter-resolved unit (cf. riverpod_lint's `@TestFor`
golden runner). Tracked as a post-0.1.0 task.
