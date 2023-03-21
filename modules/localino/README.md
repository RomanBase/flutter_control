Localino - simple json based localization solution.

## Features

Loads localization asset based on current or preferred locale.\
Formatted as Json/Map. Handles single strings, maps and lists, plurals and simple formatting.\

## Getting started

```dart
import 'package:localino/localino.dart';
```

Localino has multiple ways how to init. One of the ways is to via standalone module and simple config options.

```dart
LocalinoModule.standalone(LocalinoOptions(
    config: LocalinoConfig(locales: {
        'en_US': 'assets/localization/en_US.json',
        'es_ES': 'assets/localization/es_ES.json',
    }),
));
```

## Usage

```dart
LocalinoProvider.instance.localize('localization_key');
```

## Additional information

Localino is build as module for [Control].

```dart
Control.initControl(
  modules: [
    LocalinoModule(...)  
  ],
);
```
