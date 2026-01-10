# Localino

[![Pub Version](https://img.shields.io/pub/v/localino)](https://pub.dev/packages/localino)

`Localino` is a powerful, yet simple, JSON-based localization solution for Flutter.

It helps you easily internationalize your Flutter application by loading translations from JSON files. It supports string formatting, plurals, and can be extended with other packages from the Localino ecosystem for remote synchronization and code generation.

## Features

-   **Simple & Flexible**: Uses easy-to-manage JSON files for your translations.
-   **Automatic Locale Detection**: Loads translations based on system settings or user preferences.
-   **Rich Translation Syntax**:
    -   Handles single strings, maps, and lists.
    -   Supports pluralization via `localizePlural`.
    -   Supports string interpolation via `localizeFormat`.
-   **Extensible**: Integrates seamlessly with the [Control](https://pub.dev/packages/flutter_control) framework or can be used standalone.
-   **Ecosystem**: Works with [Localino Live](https://pub.dev/packages/localino_live) for over-the-air translation updates and [Localino Builder](https://pub.dev/packages/localino_builder) for type-safe access.

## Getting Started

### 1. Add Dependency

Add `localino` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  localino: # Use the latest version from pub.dev
```

### 2. Create Translation Files

Create a JSON file for each language you want to support. For example, `assets/localization/en.json`:

```json
{
  "app_title": "My Awesome App",
  "welcome_message": "Welcome, {user}!",
  "inbox_items": {
    "0": "You have no new messages.",
    "1": "You have one new message.",
    "other": "You have {count} new messages."
  }
}
```

And `assets/localization/cs.json`:
```json
{
  "app_title": "Moje Úžasná Aplikace",
  "welcome_message": "Vítej, {user}!",
  "inbox_items": {
    "0": "Nemáte žádné nové zprávy.",
    "1": "Máte jednu novou zprávu.",
    "2": "Máte {count} nové zprávy.",
    "5": "Máte {count} nových zpráv.",
    "other": "Máte {count} nových zpráv."
  }
}
```

### 3. Configure Assets

Declare your localization assets in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/localization/
```

### 4. Initialize Localino

In your `main.dart`, initialize `Localino` before running your app. The easiest way is to use the `standalone` module.

```dart
import 'package:flutter/material.dart';
import 'package:localino/localino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LocalinoModule.standalone(LocalinoOptions(
    config: LocalinoConfig(
      // A map of your supported locales and their asset paths.
      locales: LocalinoAsset.map(locales: [
        'en', // assets/localization/en.json
        'cs', // assets/localization/cs.json
      ]),
    ),
  ));
  
  runApp(MyApp());
}
```

## Usage

To use `Localino`, you'll need to add its delegate to your `MaterialApp`.

```dart
class MyApp extends StatelessWidget with LocalinoProvider {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use the Localino delegate for Material/Cupertino widgets
      localizationsDelegates: [
        LocalinoProvider.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalinoProvider.delegate.supportedLocales(),
      home: MyHomeScreen(),
    );
  }
}
```

You can then access your translations anywhere in your app using the `LocalinoProvider` mixin or the static `LocalinoProvider.instance`.

### Using the `LocalinoProvider` Mixin

This is the recommended way for Widgets or other classes.

```dart
class MyHomeScreen extends StatelessWidget with LocalinoProvider {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Simple localization
        title: Text(localize('app_title')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Localization with formatting
            Text(localizeFormat('welcome_message', {'user': 'Alex'})),
            // Pluralization
            Text(localizePlural('inbox_items', 5, {'count': '5'})),
          ],
        ),
      ),
    );
  }
}
```

### Using the Static Instance

You can also access translations directly from the static provider.

```dart
String title = LocalinoProvider.instance.localize('app_title');
```

## The Localino Ecosystem

Take localization to the next level with these packages:

-   **[localino.app](https://localino.app)**: A web-based admin panel for managing your translations collaboratively.
-   **[localino_live](https://pub.dev/packages/localino_live)**: Enables over-the-air (OTA) updates for your translations. Push new languages or fix typos without releasing a new app version.
-   **[localino_builder](https://pub.dev/packages/localino_builder)**: Generates type-safe Dart code from your JSON files, preventing typos and providing autocompletion.

### Example with `localino_live`

When using `localino_builder` and `localino_live`, initialization becomes even simpler. The configuration is loaded automatically from a generated `setup.json` file.

```dart
// main.dart with localino_live
await LocalinoModule.standalone(LocalinoLive.options(
  remoteSync: true, // Enable OTA updates
));
```
