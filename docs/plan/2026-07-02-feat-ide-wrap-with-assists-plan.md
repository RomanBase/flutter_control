# feat: IDE "Wrap with" code assists for flutter_control

**Type:** enhancement · **Date:** 2026-07-02 · **Branch:** `feat/ide-wrap-hints`

## Summary

Ship a companion Dart package, `control_lint`, that adds IDE refactor
assists — the "Wrap with …" lightbulb hints — for `flutter_control`'s reactive
builder widgets. When a developer places the cursor on a widget expression in
VS Code or IntelliJ/Android Studio, the editor offers:

- **Wrap with ControlBuilder**
- **Wrap with ControlBuilderGroup**
- **Wrap with FieldBuilder**
- **Wrap with ListBuilder**

This mirrors what `flutter_bloc` ("Wrap with BlocBuilder") and `riverpod`
("Wrap with Consumer") give their users, but for flutter_control's own widgets.

## Motivation

flutter_control ships reactive builders (`ControlBuilder`, `FieldBuilder`, …)
but wrapping an existing widget in one is manual, boilerplate-heavy typing.
Competing state-management packages provide one-click wrap assists; flutter_control
does not, which is a papercut for adopters and a discoverability gap for the
builders themselves.

## Key research findings (drives the whole approach)

| Finding | Source | Consequence |
|---|---|---|
| BLoC ships this feature **twice** — TS `CodeActionProvider` (VS Code) + Kotlin `IntentionAction` (IntelliJ). No shared analyzer layer. | felangel/bloc `extensions/vscode`, `extensions/intellij` (`BlocWrapWithIntentionAction.kt`) | Do **not** copy BLoC's dual-native approach — 2× code. |
| `custom_lint` (invertase) is **archived (2026-03-24)**; maintainer recommends migrating to `analysis_server_plugin`. | invertase/dart_custom_lint README + issue #379 | Do **not** build on `custom_lint`. |
| **`analysis_server_plugin`** is the official, maintained path (Dart team, tools.dart.dev). Runs *inside* the analysis server → assists surface natively in **both** VS Code and IntelliJ. Requires **Dart 3.10 / Flutter 3.38+**. | pub.dev `analysis_server_plugin` 0.3.19; dart.dev/tools/analyzer-plugins | This is the chosen tech. |
| **riverpod_lint already migrated** its "Wrap with Consumer/ProviderScope" assists to `analysis_server_plugin`. Exact template to copy. | rrousselGit/riverpod `packages/riverpod_lint/lib/src/assists/wrap/` | Copy `wrap_with_consumer.dart` structure. |

### Chosen approach

One new Dart package `control_lint`, built on `analysis_server_plugin`.
Each assist is a `ResolvedCorrectionProducer` subclass registered by a `Plugin`
in `lib/main.dart`. Consumers enable it via the top-level `plugins:` block in
`analysis_options.yaml`. No VS Code extension, no IntelliJ plugin, no
`custom_lint` dependency.

## Scope

### In scope (v1)

Four **builder-callback** assists, all sharing one transform shape (wrap the
selected widget into a `builder:` callback's `return`):

| Assist | Wrapped output (before → after) | Required seed arg |
|---|---|---|
| ControlBuilder | `Text('x')` → `ControlBuilder(control: control, builder: (context, value) { return Text('x'); })` | `control:` (typed `dynamic`) |
| ControlBuilderGroup | → `ControlBuilderGroup(controls: [control], builder: (context, values) { return Text('x'); })` | `controls:` (List) |
| FieldBuilder | → `FieldBuilder(control: control, builder: (context, value) { return Text('x'); })` | `control:` (`FieldControl<T>`) |
| ListBuilder | → `ListBuilder(control: control, builder: (context, list) { return Text('x'); })` | `control:` (`FieldControl<List<T>>`) |

Decisions locked with user:
- **v1 scope = the 4 builder-callback assists.** `LoadingBuilder` (named
  `WidgetBuilder` slots) and `CaseWidget<T>` (`builders:{}` map + `activeCase:`)
  do **not** fit the single-callback shape — deferred to v2 with their own
  transform design.
- **`control:` seed = linked-edit placeholder.** Insert `control: control,` with
  `control` as an IDE linked-edit region, auto-selected so the developer types
  the real observable immediately (riverpod-style). Same for `controls: [control]`.

### Out of scope (v2 / follow-ups)

- `LoadingBuilder` and `CaseWidget<T>` wrap assists (need bespoke transforms —
  which slot / map key receives the widget, where `activeCase` comes from).
- Diagnostics/lints (e.g. "this builder's `control` is never bound"). Assists only.
- Generic `<T>` inference — impossible at insertion time since `control:` is a
  placeholder; emit bare constructor, developer adds `<T>` when wiring the control.

## Design details

### Transform mechanics (per riverpod_lint / analysis_server_plugin)

- Node selection: nearest enclosing widget-typed `InstanceCreationExpression`
  (or the `NamedType` inside it) covering the cursor — mirror Flutter's built-in
  "Wrap with …". Gate with `widgetType.isAssignableFromType(node.staticType)`.
- Edit = **two insertions** around the node's source range (no subtree re-serialize):
  - `builder.addSimpleInsertion(node.offset, '<Prefix>ControlBuilder(control: ')`
  - plus the linked-edit for `control` and the `builder:` callback opener
  - `builder.addSimpleInsertion(node.end, '; },)')`
- Auto-import: everything in flutter_control is re-exported from the single barrel
  `package:flutter_control/control.dart` — so `builder.importLibraryElement`
  (or the `importX()` helper pattern riverpod uses) always targets that one URI.
  Prefixed imports (`import '...' as fc;`) → inserted name must be prefixed
  (`fc.ControlBuilder`); the analyzer builder machinery handles this.
- `const` handling: strip a directly-attached leading `const` on the wrapped
  widget (its body now lives in a non-const closure). Document enclosing-const
  contexts as a known limitation.
- Callback body: block body with `return` (not arrow), real param names
  (`context`, `value`/`values`/`list`) so `dart format` lays it out stably and
  the developer can consume the value.
- Undo: single `SourceChange` → one Ctrl/Cmd+Z reverts wrap + import atomically.

### Package structure

**Prerequisite fact-check (do FIRST, before scaffolding):** confirm from riverpod_lint's
actual source how `analysis_server_plugin` registration works — specifically whether
`registry.registerAssist(...)` requires **one `ResolvedCorrectionProducer` subclass per
`AssistKind`**. That answer decides the file layout below. If one producer class per kind
is required, keep 4 thin producers that each just supply config to a shared function
(NOT a base class — see next note). If not, one `wrap_assists.dart` with a
`List<WrapAssistSpec>` + loop registration is simpler.

**Abstraction decision (from simplicity review):** the 4 assists share one transform
that differs only in strings (class name, seed-arg text, `AssistKind` id) + the widget
type check. That is **table-driven config, not an inheritance hierarchy** — do NOT build
an abstract `_wrap_widget_base` class with override points. Use a single parameterized
function/producer taking a `WrapAssistSpec` record `{className, seedArgText, seedIsList,
assistKindId, priority}`. Fallback (VGV review): if `const`-strip or prefixed-import
handling forces per-assist branching, prefer 4 small duplicated producers over the wrong
abstraction.

```
control_lint/
  pubspec.yaml            # environment: sdk ^3.10.0; deps: analysis_server_plugin, analyzer, analyzer_plugin
  analysis_options.yaml   # include: package:lints/recommended.yaml  (match control_core, NOT very_good_analysis)
  lib/
    main.dart             # final plugin = _ControlLintPlugin(); registers 4 assists via WrapAssistSpec list
    src/
      wrap_assist.dart    # parameterized producer/function + WrapAssistSpec + widgetType checker + barrel URI const
      # (4 thin per-kind producers here ONLY if registration API requires one class per AssistKind)
  test/
    assists/
      wrap_widget.dart                        # @TestFor.* input fixture
      wrap_widget.wrap_with_control_builder-<offset>.assist.dart   # golden output
      ... (goldens per assist per cursor offset)
    test_annotation.dart                      # TestFor marker
  example/                # SINGLE Dart file: MaterialApp + 4 trivial build() methods, one per assist.
                          # NOT a full app (no routing/theming). Only exists for manual IDE verification.
  README.md
```

Note: `type_checkers.dart` collapsed into `wrap_assist.dart` — one barrel-URI constant +
one `TypeChecker` doesn't warrant its own file (simplicity review).

Consumer wiring (goes in `control_lint` README + main flutter_control README):

```yaml
# pubspec.yaml
dev_dependencies:
  control_lint: ^0.1.0

# analysis_options.yaml  (TOP-LEVEL block, not under `analyzer:`)
plugins:
  control_lint: ^0.1.0
# then: restart the Dart Analysis Server
```

## Files to create / modify

**New package `modules/control_lint/` (create):**

- [ ] `pubspec.yaml` — `environment: sdk: ^3.10.0` (pure-Dart, **no** `flutter:` constraint — unlike every existing module, which are Flutter packages); deps on `analysis_server_plugin: ^0.3.x`, `analyzer`, `analyzer_plugin`; include `repository:`/`homepage:` fields like sibling modules (decide URL — see below).
- [ ] `analysis_options.yaml` — `include: package:lints/recommended.yaml` (match `control_core`; do NOT introduce `very_good_analysis` — not used in this repo).
- [ ] `lib/main.dart` — `_ControlLintPlugin extends Plugin`; `register()` registers the 4 assists from a `WrapAssistSpec` list.
- [ ] `lib/src/wrap_assist.dart` — parameterized producer/function + `WrapAssistSpec` + `widgetType` checker + barrel-URI const + (4 thin per-kind producers only if the registration API requires them).
- [ ] `test/assists/wrap_widget.dart` + goldens `wrap_widget.wrap_with_*-<offset>.assist.dart` + `test/test_annotation.dart`.
- [ ] `example/` — single-file MaterialApp with 4 trivial `build()`s for manual VS Code + IntelliJ verification.
- [ ] `README.md` — setup, SDK gate, restart-analysis-server note, monorepo/path variant.

**Modify (flutter_control repo):**

- [ ] `README.md` (root) — new "IDE assists" section pointing at `control_lint`.
- [ ] `CHANGELOG.md` (root) — note companion tooling package.
- [ ] **`ci/lib/ci.dart`** — the repo's real publishing/CI harness (a Dart CLI, NOT GitHub Actions). Its `modules` list drives `clean`/`pubGet`/`deploy`, all via **`flutter` commands** (`flutter clean`, `flutter pub get`, `flutter pub publish`). `control_lint` is **pure Dart** → those `flutter` commands are wrong for it. Add a **separate `dartModules` list** + Dart-command variants (`dart pub get` / `dart pub publish`), OR special-case this one module. Also add `ci/bin/deploy_control_lint.dart` (mirror the existing `deploy_*.dart`). While here, clean up the **stale** `control_annotations`/`control_builder` entries (not on disk).
- [ ] **`.github/workflows/dart.yml`** — currently runs `flutter pub get` + `flutter test` at **repo root only** (never enters `modules/`; existing modules aren't CI-tested at all). Uses `subosito/flutter-action@v2` at latest-stable Flutter → **already satisfies Dart 3.10+** (the SDK floor is a *pubspec* concern, not a runner concern). Add a job that `cd modules/control_lint && dart pub get && dart test` (Dart, not Flutter; `dart test` runs the golden harness — NOT `dart analyze`, which doesn't exercise assists).

**Decisions:**

- **Placement: `modules/control_lint/`** — same directory as `control_core`/`localino*`, but note it is a **different artifact kind**: pure-Dart analyzer-plugin vs the others' Flutter packages. It is *not* depended on by the root `pubspec` (siblings are pulled from pub.dev by version constraint, not path); consumers add it to *their own* `dev_dependencies` + `plugins:` block.
- **Naming: `control_lint`** — matches `riverpod_lint`/`bloc_lint` and the framework pub name.
- **Repository URL**: existing pubspecs bake `github.com/romanbase/flutter_control`, but the working remote is `github.com/SedlarDavid/flutter_control`. Pick one and use it consistently in the new pubspec (flag for the maintainer).
- **Version**: start `0.1.0` (new tool; `0.x` defensible). Include `repository:`/`homepage:` for pub.dev score parity with siblings.

## Testing strategy

Adopt riverpod_lint's **golden-file assist harness** (the current, maintained pattern):

1. Input fixture annotated with `@TestFor.wrap_with_control_builder` etc.
2. Test parses fixture → runs each registered assist at every candidate cursor
   offset → diffs produced edit against the checked-in `.assist.dart` golden.
3. Per-offset regression coverage for wrapping behavior.

**Automated test cases (golden harness, run via `dart test`):**

- [ ] `Text('x')`, cursor inside → "Wrap with ControlBuilder" offered (assist appears in produced list).
- [ ] Applied output golden = `ControlBuilder(control: control, builder: (context, value) { return Text('x'); })` with barrel imported. Assert the produced `SourceChange` contains a **linked-edit group** on `control` (check the group's presence/offset, not just the text).
- [ ] Golden files are checked in **already `dart format`-clean**; test formats the golden and diffs against the checked-in file (this is what "survives `dart format`" means as a checkable assertion).
- [ ] Assist produces exactly **one `SourceChange`** (the checkable proxy for "single-undo atomic"; true undo behavior is IDE-runtime → manual list).
- [ ] `const Text('x')` → golden shows `const` stripped.
- [ ] Prefixed import (`as fc`) fixture → golden uses `fc.ControlBuilder`.
- [ ] Non-widget expression (e.g. `42`) → **no** assist in produced list.
- [ ] Already inside a flutter_control builder → assist still offered; golden shows a single added nesting level (no duplicate wrap).
- [ ] Each of the 4 assists has its own fixture + per-offset goldens.
- [ ] CI runs the harness via **`dart test`** inside `modules/control_lint` (NOT `dart run` — a `Plugin` has no `main`; and `dart analyze` does not exercise assists).

**Manual verification (IDE-runtime, can't be unit-tested):**

- [ ] Assist visible + applies in VS Code (Dart-Code quick-fix menu) via `example/`.
- [ ] Assist visible + applies in IntelliJ/Android Studio (Alt+Enter) via `example/` — **verify early**, assist rendering in the new plugin system is newer than lints/fixes.
- [ ] Single Ctrl/Cmd+Z reverts wrap + import together (atomic undo — runtime behavior).

## Risks & open questions

| Risk | Mitigation |
|---|---|
| **SDK gate**: `analysis_server_plugin` needs Dart 3.10 / Flutter 3.38+; flutter_control itself targets `sdk >=3.0.0`. Below-min → plugin silently doesn't load. | The **lint package** pins `sdk: ^3.10.0` (independent of flutter_control's constraint). README states the min SDK + the "silent no-load below min" symptom. Consumers on older SDKs just don't get assists — flutter_control runtime unaffected. |
| **IntelliJ assist rendering** in the new plugin system is less battle-tested than in VS Code. | Manual-verify in IntelliJ in the very first milestone via `example/`, before building all 4 assists. |
| **Analyzer major-version churn** (element/fragment/AST API drift across analyzer 9→14). | Pin analyzer constraint to match the targeted SDK; golden tests catch breakage on upgrade. |
| **Menu clutter / label collision** with Flutter's & riverpod's "Wrap with …". | Plain labels for v1; revisit wording ("… (flutter_control)") if user testing shows confusion. |
| **Restart requirement**: editing `analysis_options.yaml` needs an analysis-server restart; new users won't know. | Prominent README step; can't be signaled in-product (plugin isn't loaded yet). |
| **Monorepo/path setup** differs (path dep vs pub vs workspace). | README documents the `plugins:` path-dependency variant. |
| **`ci/` harness is Flutter-only** (`flutter clean/pub get/publish`) — will misbehave on a pure-Dart package. | Add a `dartModules` path in `ci/lib/ci.dart` using `dart` commands + a `deploy_control_lint.dart`. Do NOT add this module to the existing Flutter `modules` list. |
| **Registration API assumption** — plan assumes one producer per `AssistKind`; unverified. | Fact-check riverpod_lint source before scaffolding (milestone 0); file layout follows the answer. |

## Build sequence (milestones → PRs)

Plan-splitting review recommends **4 independently-mergeable PRs** along these
milestones; each leaves the codebase working. Milestone 0 is a fact-check folded
into PR 1.

0. **Fact-check (do first, no code)** — from riverpod_lint source: does registration need one producer class per `AssistKind`? Confirms file layout + whether the "shared function vs 4 producers" question is even live.
1. **PR 1 — Spike:** scaffold `modules/control_lint/`, ONE assist (`WrapWithControlBuilder`, copy `WrapWithConsumer`), single-file `example/`. Manually verify the lightbulb appears + applies in **both** VS Code and IntelliJ. No automated tests yet. De-risks the IntelliJ unknown. *Deps: none.*
2. **PR 2 — Remaining 3 assists + shared spec + refinements:** parameterize the transform (`WrapAssistSpec`), add Group/Field/List, layer in linked-edit `control:` seed, `const`-strip, prefixed-import handling across all 4. *Deps: PR 1.*
3. **PR 3 — Golden test harness + acceptance tests:** riverpod-style `TestFor` fixtures + per-offset goldens + the full automated matrix above. *Deps: PR 2.*
4. **PR 4 — Docs, CI, publish:** READMEs + CHANGELOG; `ci/lib/ci.dart` `dartModules` path + `deploy_control_lint.dart` (+ stale-entry cleanup); `dart.yml` `dart test` job for the module; publish `0.1.0`. *Deps: PR 3.*

## Reference source files

- flutter_control widgets: `lib/src/widget/builder_widget.dart` (`ControlBuilder` — `control` is `dynamic`; `ControlBuilderGroup`), `lib/src/widget/field_builder.dart` (`FieldBuilder`, `ListBuilder`, `LoadingBuilder`), `lib/src/component/case_widget.dart` (`CaseWidget`), `lib/control.dart` (single barrel + `ControlWidgetBuilder<T>` typedef).
- Copy-from templates: riverpod `packages/riverpod_lint/lib/src/assists/wrap/wrap_with_consumer.dart` & `wrap_with_provider_scope.dart`; registration `packages/riverpod_lint/lib/main.dart`; test harness `packages/riverpod_lint_flutter_test/test/assists/`.
- Official docs: `dart-lang/sdk` `pkg/analysis_server_plugin/doc/{writing_assists,using_plugins}.md`; pub.dev `analysis_server_plugin`.
