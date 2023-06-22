Localino Live - implementation of LocalinoRemoteApi via Localino REST API (https://api.localino.app).

## Features

Loads localization asset based on current or preferred locale.\
Formatted as Json/Map. Handles single strings, maps and lists, plurals and simple formatting.\

## Getting started

Add library to your pubspec.yaml under dev_dependencies.

```yaml
dev_dependencies:
  build_runner: 2.4.0
  localino_builder: 0.1.0
```

Add `build.yaml` to your project files to configure builder and localino project.

```yaml
targets:
  $default:
    builders:
      localino_builder:
        options:
          space: 'your space id'
          project: 'your project id'
          access: 'your access token'
```


## Usage

Just run `build_runner` to download your translations into asset folder.

```
flutter pub run build_runner build
```

## Additional information

Localino can be used as standalone package to manage assets localization. But true power comes with other packages:

Localino Admin: [localino.app](https://localino.app)
Localino Flutter: [localino](https://pub.dev/packages/localino)
Localino Live: [localino_live](https://pub.dev/packages/localino_live)
Localino Builder: [localino_builder](https://pub.dev/packages/localino_builder)