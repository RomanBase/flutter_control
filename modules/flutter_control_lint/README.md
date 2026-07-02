# flutter_control_lint

IDE "Wrap with …" code assists for the
[flutter_control](https://pub.dev/packages/flutter_control) framework — wrap a
widget in `ControlBuilder` (and, later, its siblings) straight from the editor
lightbulb, in both VS Code and IntelliJ / Android Studio.

Built on the official
[`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin), so
the assists run inside the Dart analysis server and appear natively in every
analyzer-backed IDE — no separate VS Code extension or IntelliJ plugin.

> **Status: PR1 spike.** Ships a single **Wrap with ControlBuilder** assist to
> prove the pipeline end-to-end. `ControlBuilderGroup`, `FieldBuilder`, and
> `ListBuilder`, plus the linked-edit `control:` placeholder and the golden test
> harness, land in follow-up PRs.

## Requirements

- **Dart 3.10+ / Flutter 3.38+** — `analysis_server_plugin` requires it. On an
  older SDK the plugin simply does not load (no error, no assists).

## Enable it in your project

Add the plugin to the **top-level `plugins:` block** of your
`analysis_options.yaml` — NOT under `analyzer:`:

```yaml
# analysis_options.yaml
plugins:
  flutter_control_lint: ^0.1.0
```

Then **restart the Dart Analysis Server** (VS Code: "Dart: Restart Analysis
Server"; IntelliJ: invalidate caches / restart). The plugin is not loaded until
you do.

> The plugin is wired ONLY through `plugins:`. Do **not** add it to your
> `dependencies`/`dev_dependencies` — an analysis-server plugin resolves in the
> server's own isolate, and its `analyzer` constraint conflicts with the
> Flutter-SDK-pinned `meta`, so a shared pub solve fails.

### Monorepo / local path

```yaml
plugins:
  flutter_control_lint:
    path: ../flutter_control_lint
```

## Usage

Place the cursor on a widget expression and open the Quick Fix / lightbulb menu
(VS Code: `Cmd`/`Ctrl` + `.`; IntelliJ: `Alt` + `Enter`). Pick **Wrap with
ControlBuilder**:

```dart
// before (cursor on Text)
Text('hello')

// after
ControlBuilder(control: control, builder: (context, value) { return Text('hello'); })
```

Replace the `control` placeholder with a real observable
(`ActionControl`, `FieldControl`, …).

## Manual verification (this spike)

Automated golden tests arrive in a later PR. For now, verify by hand:

1. `cd example && flutter pub get`
2. Open `example/lib/main.dart` in VS Code **and** IntelliJ.
3. Ensure the analysis server has been restarted since enabling the plugin.
4. Cursor on `Text('hello')` → confirm **Wrap with ControlBuilder** is offered.
5. Apply it → confirm the wrap + the `package:flutter_control/control.dart`
   import are added, and a single undo reverts both.
