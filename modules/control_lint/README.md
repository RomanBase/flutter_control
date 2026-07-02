# control_lint

IDE "Wrap with …" code assists for the
[flutter_control](https://pub.dev/packages/flutter_control) framework — wrap a
widget in a reactive builder straight from the editor lightbulb, in both VS Code
and Android Studio / IntelliJ.

Built on the official
[`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin), so
the assists run inside the Dart analysis server and appear natively in every
analyzer-backed IDE — no separate VS Code extension or IntelliJ plugin.

Assists provided:

- **Wrap with ControlBuilder** — `control: control, builder: (context, value)`
- **Wrap with ControlBuilderGroup** — `controls: [control], builder: (context, values)`
- **Wrap with FieldBuilder** — `control: control, builder: (context, value)`
- **Wrap with ListBuilder** — `control: control, builder: (context, list)`

`control` is a placeholder to replace with a real observable.

## Requirements

- **Dart 3.10+ / Flutter 3.38+** — `analysis_server_plugin` requires it. On an
  older SDK the plugin simply does not load (no error, no assists).

## Enable it in your project

Add the plugin to the **top-level `plugins:` block** of your
`analysis_options.yaml` — NOT under `analyzer:`:

```yaml
# analysis_options.yaml
plugins:
  control_lint: ^0.1.0
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
  control_lint:
    path: ../control_lint
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

## Verifying it in the editor

The `example/` app is wired to load this plugin by path — use it to see the
assists live:

1. `cd example && flutter pub get`
2. Open `example/lib/main.dart` in VS Code and/or Android Studio.
3. Restart the analysis server (see below).
4. Cursor on any widget → open the lightbulb → confirm the four **Wrap with …**
   assists appear. Applying one wraps the widget, adds the
   `package:flutter_control/control.dart` import, and a single undo reverts both.

Assist-output is also covered by `dart test` (`test/wrap_assist_test.dart`).

## Troubleshooting

**The assists don't appear.**
Editing the `plugins:` block does not take effect until the Dart Analysis Server
restarts. VS Code: `Dart: Restart Analysis Server`. Android Studio: invalidate
caches / restart. Give it ~15s to rebuild the plugin after restarting.

**`Can't load Kernel binary: … (expected 127, found 130)` / assists vanish after
an SDK change.**
The analysis server compiles the plugin to a snapshot with *its* Dart SDK. If the
server runs an older SDK than the one that built the snapshot, the kernel version
mismatches and the plugin fails to load silently. Ensure the IDE's Dart/Flutter
SDK is 3.10+ and matches your CLI SDK (check `dart --version` vs the IDE's SDK
setting).

**The analysis server crashes right after you edit the plugin's own source.**
The cached plugin snapshot goes stale. Clear it and restart the analysis server:

```sh
rm -rf ~/.dartServer/.plugin_manager/*
```

(Only relevant when developing this plugin — consumers never hit it.)
