![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/logo.png)

---

Flutter Control is complex library to maintain App and State management.\
Library merges multiple functionality under one hood. This approach helps to tidily bound separated logic into complex solution.

```dart
import 'package:control_core/core.dart';
```

---

**Flutter Control Core**
- `Control` is main static class that creates new instance of `ControlFactory`.
- `ControlFactory` Initializes and stores Controls, Models and other Objects. Works as a direct Service Locator.\
  Factory has own **Storage**. Objects in this storage are accessible via custom **key** or **Type**. Best practice is to use Type as a key.\
  This Factory is one and only Singleton in this Library.\

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/service_locator.png)

```dart
    Control.initControl(
      entries: {
        CounterListControl: CounterListControl(),
      },
      factories: {
        CounterModel: (_) => CounterModel(),
        CounterDetailControl: (args) => CounterDetailControl(model: Parse.getArg<CounterModel>(args)),
      },
      modules: [
        LocalinoModule(LocalinoOptions()),  
      ],
      initAsync: () async {
        await loadAppConfig();
      },
    );
```

---

- `ControlModel` is base class to maintain Business Logic parts.\
  `BaseControl` is extended version of [ControlModel] with more functionality. Mainly used for robust Logic parts.\
  `BaseModel` is extended but lightweight version of [ControlModel]. Mainly used to control smaller logic parts.\

- `ControlObservable` and `ControlSubscription` are core underlying observable system and abstract base for other concrete robust implementations - mainly [ActionControl] and [FieldControl].\
  With `ControlBuilder` and `ControlBuilderGroup` on the Widget side ([flutter_control] library). These universal builder widgets can handle all possible types of Notifiers.

- `ActionControl` is one type of Observable used in this Library. It's quite lightweight and is used to notify Widgets and to provide events about value changes.\
  Has two variants - **Single** (just one listener), **Broadcast** (multiple listeners).\
  Upon dismiss of [ActionControl], every `ControlSubscription` is closed.

```dart
    final counter = ActionControl.broadcast<int>(0);

    counter.subscribe((value) => printDebug(value));
    
    void add() => counter.value++;
```

- `FieldControl` is more robust Observable solution around `Stream` and `StreamController`. Primarily is used to notify Widgets and to provide events about value changes.\
  Can listen `Stream`, `Future` or subscribe to another [FieldControl] with possibility to filter and convert values.\
  [FieldControl] comes with pre-build primitive variants as `StringControl`, `NumberControl`, etc., where is possible to use validation, regex or value clamping. And also `ListControl` to work with Iterables.\
  `FieldSink` or `FieldSinkConverter` provides **Sink** of [FieldControl].\
  Upon dismiss of [FieldControl], every `FieldSubscription` is closed.

```dart
    final counter = FieldControl<int>(0);

    counter.subscribe((value) => printDebug(value));
    
    void add() => counter.value++;
```

**Global Event System**

- `ControlBroadcast` Event stream across whole App. Default broadcaster is part of `ControlFactory` and is stored there.\
  Every subscription is bound to it's `key` and `Type` so notification to Listeners arrives only for expected data.\
  With `BroadcastProvider` is possible to subscribe to any stream and send data or events from one end of App to the another, even to Widgets and their States.
  Also custom broadcaster can be created to separate events from global/default stream.

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/broadcaster.png)

```dart
  BroadcastProvider.subscribe<int>('on_count_changed', (value) => updateCount(value));
  BraodcastProvider.broadcast('on_count_changed', 10);
```