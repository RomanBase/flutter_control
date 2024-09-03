## Part of [flutter_control] family

This library is wrapper around [shared_preferences]

Mixin provider:
```dart
class UserPrefs with PrefsProvider {
  
  String get userId => prefs.get('user_id');
  
  set userId(String value) => prefs.set('user_id', value);
}
```

Model:
```dart
final boolPref = PrefModel.boolean('visited');
final numPref = PrefModel.number('fav_num', defaultValue: -1);

void updateVisited() {
  boolPref.value = numPref.value > 0;
}
```

Instance:
```dart
  final id = PrefsProvider.instance.get('user_id');
```


