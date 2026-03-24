# Localino

A comprehensive, JSON-based localization solution for Flutter applications. Part of the [Flutter Control](https://github.com/romanbase/flutter_control) framework, but can be used standalone.

## Features

- **JSON Assets**: Load translations from simple JSON files.
- **Pluralization**: Handle complex plural forms with ease.
- **Parametrized Strings**: Support for dynamic values within translations.
- **Dynamic & List Support**: Retrieve nested objects or lists directly from your localization data.
- **System Locale Detection**: Automatically matches the device's language settings.
- **Remote Synchronization**: Fetch and cache translations from a remote source for over-the-air updates.
- **Easy Integration**: Use as a `LocalizationsDelegate` or via a simple mixin.

---

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  localino: ^2.0.0
```

### 1. Prepare Localization Assets

Create your localization files in `assets/localization/`:

**en.json**
```json
{
  "app_name": "My Awesome App",
  "welcome": "Welcome {name}!",
  "items_count": {
    "0": "No items",
    "1": "One item",
    "2": "A few items",
    "5": "Many items",
    "other": "Total of {count} items"
  },
  "gender": {
    "male": "Boy",
    "female": "Girl",
    "other": "Child"
  },
  "days": ["Monday", "Tuesday", "Wednesday"]
}
```

### 2. Setup

#### Using with Flutter Control

```dart
Control.initControl(
  modules: [
    LocalinoModule(
      LocalinoOptions(
        config: LocalinoConfig(
          defaultLocale: 'en',
          locales: LocalinoAsset.map(
            locales: ['en', 'cs'],
          ),
        ),
      ),
    ),
  ],
);
```

#### Standalone Setup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalinoModule.standalone(
    LocalinoOptions(
      config: LocalinoConfig(
        defaultLocale: 'en',
        locales: LocalinoAsset.map(
          locales: ['en', 'cs'],
        ),
      ),
    ),
  );

  runApp(MyApp());
}
```

### Localization Setup File

Instead of hardcoding `LocalinoConfig`, you can use a `setup.json` file in your assets:

**assets/localization/setup.json**
```json
{
  "space": "my_app",
  "project": "main",
  "asset": "assets/localization/{locale}.json",
  "locales": {
    "en": "2023-10-27T10:00:00Z",
    "cs": "2023-10-27T10:00:00Z"
  }
}
```

Initialize with:
```dart
LocalinoOptions(path: 'assets/localization/setup.json')
```

### 3. Integrate with MaterialApp (optional)

```dart
MaterialApp(
  localizationsDelegates: [
    LocalinoProvider.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: LocalinoProvider.delegate.supportedLocales(),
  home: HomePage(),
);
```

---

## Usage

### Basic Localization

```dart
// Direct access
LocalinoProvider.instance.localize('app_name');

// Within a Widget using a mixin
class MyWidget extends StatelessWidget with LocalinoProvider {
  @override
  Widget build(BuildContext context) {
    return Text(localize('app_name'));
  }
}
```

### Advanced Formatting

```dart
// Parametrized strings
localizeFormat('welcome', {'name': 'John'}); // Welcome John!

// Plurals
localizePlural('items_count', 0); // No items
localizePlural('items_count', 1); // One item
localizePlural('items_count', 3); // A few items
localizePlural('items_count', 10, {'count': '10'}); // Total of 10 items

// Specific values (e.g., Gender)
localizeValue('gender', 'male'); // Boy

// Lists
localizeList('days'); // ['Monday', 'Tuesday', 'Wednesday']
```

### Changing Locale

```dart
LocalinoProvider.instance.changeLocale('cs');
```

---

## Remote Synchronization

Localino supports fetching translations from a remote API. This requires implementing `LocalinoRemoteApi`.

```dart
class MyRemoteApi extends LocalinoRemoteApi {
  @override
  Future<Map<String, dynamic>> getRemoteTranslations(String locale, {DateTime? timestamp, String? version}) async {
    // Fetch from your server
  }
  
  // Implement other methods: getRemoteSetup, getLocalCache, setLocalCache
}

// In options:
LocalinoOptions(
  remote: (_) => MyRemoteApi(),
  remoteSync: true,
)
```
