## Part of [flutter_control] family

This library is wrapper around [shared_preferences]

Mixin provider:
```dart
class UserPrefs with PrefsProvider {
  
  String get userId => prefs.get('user_id');
  
  set userId(String value) => prefs.set('user_id', value);
}
```

Instance:
```dart
  final id = PrefsProvider.instance.get('user_id');
```

Standalone Module Initialization:
```dart
class UserPrefs with PrefsProvider {
  Control.initControl(
      modules: [
          ConfigModule(),
      ],
  );
}
```


