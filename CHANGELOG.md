## [4.0.2] - Quality of life updates

## [4.0.0] - BREAKING: Widget [args] moved to [CoreContext]. All widget constructors should be

`const` now. All Widget/State arguments are now handled by [Element].

- Changed from ```Property get prop => mount<Property>()``` to ```context.use<Property>()```
- We are no more able to access `context` and `args` from outside of init/build functions.
- 3.x version is still supported and runs on latest Dart/Flutter version.
  Check ![GitHub](https://github.com/RomanBase/flutter_control/tree/3.x).

## [3.0.1] - Flutter & Dart 3.0

## [2.6.3] - Localino and localino_live integration

## [2.5.1] - Multiple libs

Library is now separated to multiple modules:

- control_core
- control_config
- localino
- flutter_control

## [2.1.3] - Improvements

Minor improvements and quality of life changes.

## [2.1.0] - Base

New unified observable system. Updated localization and root components.

## [2.0.0] - Null-safety

Migrate library to Dart 2.0 and Null Safety.

## [1.0.0] - Core

Upgraded architecture and stable version.

## [0.15.3] - Vanilla.

Base architecture and pattern, Factory and Store, Model, Widget and other Components.

---

**Main Structure**

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure.png)