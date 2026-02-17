# Localino Live

[![Pub Version](https://img.shields.io/pub/v/localino_live)](https://pub.dev/packages/localino_live)

The official implementation of `LocalinoRemoteApi` for the [localino](https://pub.dev/packages/localino) package. `localino_live` connects your Flutter app to the [localino.app](https://localino.app) service, enabling Over-The-Air (OTA) updates for your translations.

## Features

-   **Live Updates**: Fetches the latest translations from the Localino backend.
-   **Over-The-Air**: Push translation changes to your users without releasing a new version of your app.
-   **Offline Caching**: Caches translations on the device, so your app works offline.
-   **Seamless Integration**: Integrates automatically with the `localino` package.

## Getting Started

### Prerequisites

Before using `localino_live`, you need a project set up on [localino.app](https://localino.app). From your project dashboard, you will get a **Space ID**, **Project ID**, and an **Access Token**.

### 1. Add Dependencies

Add `localino` and `localino_live` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  localino:
  localino_live:
```

### 2. Initialization

The recommended way to initialize `localino` with `localino_live` is to use the `localino_builder` package. The builder will generate a `setup.json` file in your assets with all the necessary configuration from your `localino.yaml` file.

However, you can also initialize it manually. Use `LocalinoLive.options()` to create the configuration for `LocalinoModule`.

```dart
// In your main.dart
import 'package:flutter/material.dart';
import 'package:localino/localino.dart';
import 'package:localino_live/localino_live.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LocalinoModule.standalone(
    // Use LocalinoLive.options to configure remote sync
    LocalinoLive.options(
      setup: LocalinoSetup(
        space: 'YOUR_SPACE_ID',       // From localino.app
        project: 'YOUR_PROJECT_ID',   // From localino.app
        access: 'YOUR_ACCESS_TOKEN',  // From localino.app
      ),
      remoteSync: true, // Enable OTA updates
    ),
  );
  
  runApp(MyApp());
}
```

### 3. Usage

Once initialized, `localino_live` works in the background. You use the standard `localino` API to get your translations. `localino` will automatically fetch remote translations and update the local cache.

```dart
class MyWidget extends StatelessWidget with LocalinoProvider {
  @override
  Widget build(BuildContext context) {
    // Translations are fetched automatically
    return Text(localize('my_remote_key'));
  }
}
```

## The Localino Ecosystem

`localino_live` is part of a larger ecosystem to make localization seamless.

-   **[localino.app](https://localino.app)**: A web-based admin panel for managing your translations.
-   **[localino](https://pub.dev/packages/localino)**: The core localization package for Flutter.
-   **[localino_builder](https://pub.dev/packages/localino_builder)**: Generates type-safe Dart code and configuration from your localino setup.

By using these tools together, you can achieve a fully automated and type-safe localization workflow with OTA updates.