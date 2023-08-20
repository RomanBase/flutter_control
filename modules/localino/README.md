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
        config: LocalinoConfig(
        locales: LocalinoAsset.map(locales: [
                'en',
                'cs',
            ]),
        ),
    ));
```

Initialization with [localino_builder] and [localino_live] where config is loaded from assets folder.
```dart
    LocalinoModule.standalone(LocalinoLive.options(
        remoteSync: true,
    ));
```

Sub-Localization Object to store other data (like international state names, tel. phones, etc.) based on parent (main) Localization instance.
```dart
    Localino subLocalization = LocalinoProvider.instance.instanceOf(assets);
```

---

Mixin provider:
```dart
class CustomObject with LocalinoProvider {
  
  String name = localize('name');
}
```

Instance:
```dart
 String name = LocalinoProvider.instance.localize('name');
```

---

By default Localino is build as module for [Control] and uses [control_config] to store preferences (chosen locale).

```dart
Control.initControl(
  modules: [
    ConfigModule(),
    LocalinoModule(options)
  ],
);
```

---

Localino can be used as standalone package to manage assets localization. But true power comes with other packages:

Localino Admin: [localino.app](https://localino.app)
Localino Flutter: [localino](https://pub.dev/packages/localino)
Localino Live: [localino_live](https://pub.dev/packages/localino_live)
Localino Builder: [localino_builder](https://pub.dev/packages/localino_builder)
