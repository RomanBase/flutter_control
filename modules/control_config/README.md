# control_config

`control_config` is a `control_core` module that provides a robust and reactive layer over `shared_preferences`. It simplifies managing user preferences and configuration settings by offering type-safe access and automatic change notifications.

This library is ideal for:
-   Persisting user settings (e.g., dark mode, language, custom preferences).
-   Storing application configuration flags.
-   Providing reactive access to preference changes throughout your app.

## Features

-   **Seamless Integration**: Designed to work effortlessly with `control_core`'s dependency injection system.
-   **Type-Safe Preferences**: Set and get `bool`, `String`, `int`, `double`, and even `dynamic` (JSON) values safely.
-   **Reactive Preference Models**: `PrefModel` allows you to observe changes to individual preference keys.
-   **Simplified Access**: `PrefsProvider` mixin for easy access to `ControlPrefs` from any class.
-   **Modular Setup**: `ConfigModule` for integrating preferences into your application's `ControlFactory` initialization.

## Installation

Add `control_config` to your `pubspec.yaml` file:

```yaml
dependencies:
  control_config: ^2.0.0
```

## Setup

### Recommended Setup

Integrate `ConfigModule` into your `Control.initControl()` call. This is typically done in your `main()` function.

```dart
import 'package:control_core/core.dart';
import 'package:control_config/config.dart';
import 'package:flutter/widgets.dart'; // Required for binding initialization.

void main() async {
  // Required by shared_preferences before it can be used.
  WidgetsFlutterBinding.ensureInitialized(); 

  Control.initControl(
    modules: [
      ConfigModule(), // This will automatically initialize SharedPreferences
    ],
  );
  
  // onReady ensures that all module initializations are complete.
  await Control.factory.onReady();
  print('Control System and Preferences are ready!');
  
  // Example of using PrefsProvider after setup
  final settings = UserSettings();
  settings.username = 'Alex';
  print('Username from settings: ${settings.username}');
}
```

### Standalone Setup

You can also initialize `control_config` without the full `Control.initControl` ceremony. This is useful for smaller apps or tests.

```dart
import 'package:control_config/config.dart';
import 'package:control_core/core.dart';
import 'package:flutter/widgets.dart';

void main() async {
  // Required by shared_preferences before it can be used.
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // This initializes ControlFactory with just the ConfigModule.
  await ConfigModule.standalone();

  // onReady ensures that the module is fully initialized.
  await Control.factory.onReady();
  print('Preferences are ready for standalone use!');

  // Now you can use PrefsProvider
  final prefs = PrefsProvider.instance;
  prefs.setBool('is_first_launch', false);
  print('Is first launch: ${prefs.getBool('is_first_launch')}');
}
```

## Usage

### 1. Accessing Preferences with `PrefsProvider`

Mix `PrefsProvider` into your classes for convenient access to `ControlPrefs`. This is useful for business logic classes that need to read or write multiple preference values.

```dart
import 'package:control_config/config.dart';
import 'package:control_core/core.dart';

class UserSettings with PrefsProvider {
  // Directly access preferences via the 'prefs' getter.
  String get username => prefs.get('username', defaultValue: 'Guest')!;
  set username(String value) => prefs.set('username', value);

  bool get darkMode => prefs.getBool('dark_mode', defaultValue: false);
  set darkMode(bool value) => prefs.setBool('dark_mode', value);
}

void demonstrateSettings() {
  final settings = UserSettings();

  print('Initial dark mode: ${settings.darkMode}');
  settings.darkMode = true;
  print('Updated dark mode: ${settings.darkMode}');
}
```

### 2. Reactive Preferences with `PrefModel`

`PrefModel` creates an observable wrapper around a single preference key. It extends `ChangeNotifier`, so you can listen for changes, making it perfect for reactive business logic.

```dart
import 'package:control_config/config.dart';
import 'package:control_core/core.dart';

// Create PrefModel instances for specific preference keys.
final darkModePref = PrefModel.boolean('dark_mode', defaultValue: false);

final sub = darkModePref.subscribe((value) => print('Dark mode enabled: $value'));
```

### 3. Storing and Retrieving Custom Data (JSON)

You can store and retrieve complex objects by providing `get` and `set` converter functions to `PrefModel.data`.

```dart
import 'package:control_config/config.dart';

class AppUser {
  final String id;
  final String name;

  AppUser({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

// Create a reactive PrefModel for the AppUser object.
final currentUserPref = PrefModel.data<AppUser>(
  'current_user',
  (json) => AppUser.fromJson(json), // Getter: from JSON to AppUser
  (user) => user?.toJson(), // Setter: from AppUser to JSON
);

void manageUserSession() {
  // Save a user. This automatically converts to JSON and saves.
  final user = AppUser(id: '123', name: 'Alex');
  currentUserPref.value = user;
  
  // Retrieve the user. This automatically reads the JSON and converts it back.
  final savedUser = currentUserPref.value;
  print('Saved user: ${savedUser?.name}'); // Prints: "Saved user: Alex"
}
```
