![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/logo.png)

---
Core library for FLutter and Dart projects.\
Simple **Service Locator** to access objects from anywhere. Easy way to switch the implementation of interfaces and for mocks/tests.
Solves **Event Handling** across app.
Implements **Observables** for more robust Change/ValueNotifier and simplified Streams.
Adds **Model** and **Control** classes to line basic lifecycle of classes.

```dart
import 'package:control_core/core.dart';
```
---

**Control Factory**
- `Control` Main and only singleton class. Initializes `ControlFactory` that serves as **Service Locator** with Factory and object initialization.
- `ControlFactory` Is responsible for creating and storing given `factories` and `entries` (like singletons). Then locating this services and retrieving on demand.\
  - Factory has own **Storage**. Objects in this storage are accessible via custom **key** or **Type**. Best practice is to use Type as a key (typically Interfaces).
  - Also **custom** factory can be created with `Control.newFactory()` to separate factories from global/default factory.
- `ControlModule` robust way how to load all resources into factory at once. Easy way how to 'plug in/out' modules.

```dart
void main() {
  Control.initControl(
    entries: {
      CounterListControl: CounterListControl(),
    },
    factories: {
      CounterIterface: (_) => CounterModel(),
    },
    modules: [
      LocalinoModule(LocalinoOptions()),
    ],
    initAsync: () async {
      await loadAppConfig();
    },
  );
  
  Control.set<AnotherControl>(value: AnotherControl()); //Adds new 'singleton' 
  Control.add<CounterIterface>(value: BetterCounterModel()); //Changes factory of CounterIterface
  
  final counter = Control.get<CounterIterface>()!; // Returns implementation of BetterCounterModel
}
```

- `LazyControl` mixin marks object to work as lazy singleton.
- `Control.use` another way how to dynamically register and retrieve lazy singleton with initialization of concrete - default implementation.

```dart
class LazyCounterModel extends ControlModel with LazyControl {
}

void main() {
  Control.add<LazyCounterModel>(init: (_) => LazyCounterModel());
  Control.get<LazyCounterModel>(); // will initialize (if not exists) LazyCounterModel and stores it in ControlFactory, then retrieves concrete class

  Control.use<LateCounter>(value: () => LateCounter()); // will initialize (if not exists) LateCounter and stores it in ControlFactory, then retrieves concrete class
}
```

- Dependency vs Property Injection. *Best practice depends on your project and internal ideologies*.
  - Dependency Injection in Constructor is better readable - what dependencies are required to build concreate class.
  - Property Injection is more dynamic and works well with Dart mixins and extensions, but requires deeper knowledge of own code.
```dart

class A {}

class B {
  final A ref;

  const B(this.ref); //Dependency Injection
}

class C {
  A get ref => Control.get<A>()!; // Property Injection
}

void main() {
  Control.initFactory(
      entries: {
        C: C(),
      },
      factories: {
        A: (_) => A(),
        B: (_) => B(Control.get<A>()),
      }
  );
}

```

---

**Global Event System**

- `ControlBroadcast` Event stream across whole App. Default broadcaster is part of `ControlFactory` and is stored there.\
  Every subscription is bound to it's `key` and `Type` so notification to Listeners arrives only for expected data.\
  With `BroadcastProvider` is possible to subscribe to any stream and send data or events from one end of the App to the another, even to Widgets and their States.
  Also **custom** broadcaster can be created to separate events from global/default stream.

```dart
  BroadcastProvider.subscribe<int>('on_count_changed', (value) => updateCount(value));
  BraodcastProvider.broadcast('on_count_changed', 10);
```

---

**Observables**

- `ControlObservable` and `ControlSubscription` are core underlying observable system and abstract base for other concrete robust implementations - mainly [ActionControl] and [FieldControl].\
  With `ControlBuilder` and `ControlBuilderGroup` on the Widget side ([flutter_control] library). These universal builder widgets can handle all possible types of Notifiers.

- `ActionControl` is one type of Observable used in this Library. It's quite lightweight and is used to notify listeners about value changes.\
  Has tree main variants - **Single** (just one listener), **Broadcast** (multiple listeners) and **Empty** (null).\
  4th variant is **provider** that subscribe to global [BroadcastProvider].\
  On the Widget side is `ControlBuilder` to dynamically build Widgets. It's also possible to use `ControlBuilderGroup` to group values of multiple Observables.\
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

- `NotifierComponent`, `ObservableComponent<T>` are mixins that transforms any class to `Observable`.

```dart
class CounterModel extends BaseModel with ObservableComponent<int> {
  CounterModel() {
    value = 0;
  }

  void add() => value = value! + 1;
}

```

---

**Business Logic**

- `ControlModel` is base class to maintain Business Logic parts.\
  `BaseControl` is extended version of [ControlModel] with more functionality. Mainly used for robust Logic parts.\
  `BaseModel` is extended but lightweight version of [ControlModel]. Mainly used to control smaller logic parts.\

---

**Part of Control Family**
Flutter Control:  https://pub.dev/packages/flutter_control
Control Core:     https://pub.dev/packages/control_core
Control Config:   https://pub.dev/packages/control_config
Localino:         https://pub.dev/packages/localino
Localino Live:    https://pub.dev/packages/localino_live
Localino Builder: https://pub.dev/packages/localino_builder