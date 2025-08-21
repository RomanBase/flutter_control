![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/logo.png)

---
Core library for FLutter and Dart projects.
Simple **Service Locator** to access objects from anywhere. Easy way to switch the implementation of interfaces and for mocks/tests.
Solves **Event Handling** across app.
Implements **Observables** for more robust Change/ValueNotifier and simplified Streams.
Adds **Model** and **Control** classes to line basic lifecycle of classes.

```dart
import 'package:control_core/core.dart';
```
---

# Control Factory (Service Locator)

At the heart of `control_core` is the `Control` class, which provides a powerful and easy-to-use Service Locator pattern through the `ControlFactory`. This allows you to register and retrieve your app's services, models, and other objects from anywhere in your code.

## Initialization

The `Control` factory must be initialized before it can be used. This is typically done in your `main()` function.

```dart
void main() {
  Control.initControl(
    // Register singleton instances.
    entries: {
      CounterListControl: CounterListControl(),
    },
    // Register factories for lazy initialization.
    factories: {
      CounterInterface: (_) => CounterModel(),
    },
    // Use modules to organize your dependencies.
    modules: [
      LocalinoModule(LocalinoOptions()),
    ],
    // Perform asynchronous initialization.
    initAsync: () async {
      await loadAppConfig();
    },
  );
}
```

-   **`entries`**: A `Map` of objects that are registered as singletons. These objects are instantiated immediately and stored in the factory.
-   **`factories`**: A `Map` of functions that create objects on demand. This is useful for lazy initialization of your services.
-   **`modules`**: A list of `ControlModule`s, which provide a structured way to organize and register your dependencies.
-   **`initAsync`**: An optional asynchronous function that is executed during initialization. This is useful for loading configuration files or performing other asynchronous tasks.

## Retrieving Objects

You can retrieve objects from the factory using the `Control.get()` method.

```dart
// Retrieve by type.
final counter = Control.get<CounterInterface>()!;

// Retrieve by key.
final apiKey = Control.get<String>(key: 'api_key');
```

## Dynamic Registration

You can also register objects and factories dynamically after initialization.

```dart
// Register a new singleton.
Control.set<AnotherControl>(value: AnotherControl());

// Override an existing factory.
Control.add<CounterInterface>(init: (_) => BetterCounterModel());
```

## LazyControl

The `LazyControl` mixin allows you to create objects that are lazily initialized and automatically removed from the factory when they are disposed.

```dart
class LazyCounterModel extends ControlModel with LazyControl {
  // ...
}

void main() {
  Control.add<LazyCounterModel>(init: (_) => LazyCounterModel());

  // The LazyCounterModel is not created yet.

  final counter = Control.get<LazyCounterModel>()!; // Now it's created and stored.

  // When the counter is disposed, it will be removed from the factory.
}
```

## Dependency Injection vs. Property Injection

`control_core` supports both dependency injection and property injection.

**Dependency Injection (Constructor Injection)**

```dart
class A {}

class B {
  final A ref;

  const B(this.ref);
}

void main() {
  Control.initControl(
    factories: {
      A: (_) => A(),
      B: (_) => B(Control.get<A>()!),
    },
  );
}
```

**Property Injection**

```dart
class C {
  A get ref => Control.get<A>()!;
}

void main() {
  Control.initControl(
    entries: {
      C: C(),
    },
    factories: {
      A: (_) => A(),
    },
  );
}
```

---

# Global Event System

The `control_core` library provides a global event system that allows different parts of your application to communicate with each other without having a direct reference. This is achieved through the `ControlBroadcast` class and the `BroadcastProvider`.

## ControlBroadcast

The `ControlBroadcast` class is a global stream that allows you to broadcast data and events. The stream is driven by keys and object types, so listeners only receive the data they are interested in.

## BroadcastProvider

The `BroadcastProvider` is a static class that provides a simple interface for interacting with the default `ControlBroadcast` instance.

### Subscribing to Events

You can subscribe to events using the `BroadcastProvider.subscribe()` and `BroadcastProvider.subscribeEvent()` methods.

```dart
// Subscribe to an event with a specific key and type.
BroadcastProvider.subscribe<int>('on_count_changed', (value) {
  print('Count changed: $value');
});

// Subscribe to an event with a specific key.
BroadcastProvider.subscribeEvent('on_button_pressed', () {
  print('Button pressed');
});
```

### Broadcasting Events

You can broadcast events using the `BroadcastProvider.broadcast()` and `BroadcastProvider.broadcastEvent()` methods.

```dart
// Broadcast a value.
BroadcastProvider.broadcast<int>(key: 'on_count_changed', value: 10);

// Broadcast an event.
BroadcastProvider.broadcastEvent(key: 'on_button_pressed');
```

---

# Observables

`control_core` provides a powerful set of tools for managing state and reacting to changes. At the core of this system are `ControlObservable` and `ControlSubscription`, which provide the foundation for more specialized classes like `ActionControl` and `FieldControl`.

## ActionControl

`ActionControl` is a lightweight observable that is ideal for notifying listeners about simple value changes. It comes in three main variants:

*   **`ActionControl.single(value)`**: Allows only one listener to be subscribed at a time.
*   **`ActionControl.broadcast(value)`**: Allows multiple listeners to be subscribed.
*   **`ActionControl.empty()`**: A nullable version that can be used with one or more listeners.

```dart
// Create a broadcast ActionControl with an initial value of 0.
final counter = ActionControl.broadcast<int>(0);

// Subscribe to the counter and print the new value whenever it changes.
counter.subscribe((value) => print('Counter value: $value'));

// Increment the counter's value. This will trigger the subscription.
counter.value++;
```

## FieldControl

`FieldControl` is a more robust observable that is built around `Stream` and `StreamController`. It is well-suited for more complex scenarios, such as handling user input, validating data, and working with asynchronous operations.

`FieldControl` can be created with an initial value, or it can be subscribed to a `Stream` or `Future`. It also provides a `sink` for adding new values to the stream.

```dart
// Create a FieldControl with an initial value of 0.
final counter = FieldControl<int>(0);

// Subscribe to the counter and print the new value whenever it changes.
counter.subscribe((value) => print('Counter value: $value'));

// Increment the counter's value. This will add the new value to the stream and trigger the subscription.
counter.value++;
```

`FieldControl` also comes with pre-built variants for common use cases, such as `StringControl`, `NumberControl`, and `ListControl`. These variants provide additional functionality, such as validation, regex matching, and value clamping.

## ObservableComponent

The `ObservableComponent<T>` mixin allows you to transform any class into an observable. This is useful for creating custom models and controls that can be observed by other parts of your application.

```dart
class CounterModel extends BaseModel with ObservableComponent<int> {
  CounterModel() {
    value = 0;
  }

  void increment() {
    value = value! + 1;
  }
}
```

---

# Business Logic

The `control_core` library provides a set of base classes for organizing your application's business logic. These classes provide a consistent structure and lifecycle for your models and controls.

## ControlModel

`ControlModel` is the fundamental base class for all business logic components. It provides a simple lifecycle with `init()` and `dispose()` methods, and it can be easily integrated with the `ControlFactory` for dependency injection.
`BaseModel` is a lightweight version of `ControlModel` that is ideal for smaller, more focused pieces of business logic. By default, `BaseModel` prefers a "soft dispose," meaning it won't be automatically disposed by the `ControlFactory` and must be disposed manually.
`BaseControl` is a more robust version of `ControlModel` that is designed for complex business logic. It ensures that the `onInit()` method is called only once, making it ideal for controllers that manage a significant amount of state or interact with multiple services. `BaseControl` is typically used for long-lived objects that are managed by the `ControlFactory`.

## Lifecycle Management: Initializable and DisposeHandler

`control_core` provides two key components for managing the lifecycle of your objects: `Initializable` and `DisposeHandler`. These are used by `ControlModel` and its subclasses to provide a consistent and predictable lifecycle.

### Initializable

The `Initializable` class provides a standard way to initialize an object after its constructor has been called. This is useful for late property injection and for scenarios where you need to pass arguments to an object after it has been created.

```dart
class MyService implements Initializable {
  late final String apiKey;

  @override
  void init(Map args) {
    apiKey = args['api_key'];
  }
}

void main() {
  final service = Control.get<MyService>(args: {'api_key': '12345'});
}
```

### Disposable and DisposeHandler

The `DisposeHandler` mixin provides a robust way to manage the disposal of your objects. It allows you to control whether an object should be disposed automatically by the `ControlFactory` or if it should be disposed manually.

The `preferSoftDispose` property determines the disposal behavior:

*   **`true` (default for `BaseModel`):** The object will not be disposed automatically by the `ControlFactory`. You are responsible for calling the `dispose()` method manually.
*   **`false` (default for `BaseControl`):** The object will be disposed automatically by the `ControlFactory` when it is no longer needed.

```dart
class MyResource with DisposeHandler {
  void open() {
    print('Resource opened');
  }

  @override
  void dispose() {
    super.dispose();
    print('Resource closed');
  }
}

void main() {
  final resource = MyResource();
  resource.open();
  // ...
  resource.requestDispose(); // soft dispose
  resource.dispose(); // hard dispose
}
```

---

# Utilities

`control_core` includes a set of utility classes and extensions to simplify common development tasks.

## FutureBlock

`FutureBlock` is a utility class that allows you to delay the execution of a function and easily manage the timer.

```dart
final block = FutureBlock();

// Delay the execution of a function by 500 milliseconds.
block.delayed(Duration(milliseconds: 500), () {
  print('This will be executed after 500ms');
});

// Postpone the execution by another 500 milliseconds.
block.postpone(duration: Duration(milliseconds: 500));

// Cancel the delayed execution.
block.cancel();

// Triggers callback early.
block.trigger();

// Creates new FutureBlock from given parent to retrigger process
final restore = Block.extend(parent: block, duration: Duration(seconds: 1));
```

## ControlArgs

`ControlArgs` is a versatile class for storing and passing arguments. It can handle various data types and provides a convenient way to access and manage data.

```dart
final args = ControlArgs.of({'name': 'John Doe', 'age': 30});

// Get a value by key.
final name = args.get<String>(key: 'name');

// Get a value by type.
final age = args.get<int>();

// Add a new value.
args.add<bool>(key: 'is_admin', value: true);
```

## UnitId

`UnitId` is a utility class for generating unique IDs with instance marker.

```dart
UnitId.instanceId = 'hello';
UnitId.instanceCounter = prefs.get('counter', defaultValue: 5);
UnitId.onChanged = () => prefs.set('counter', UnitId.instanceCounter);

// Generate a unique ID based on the current timestamp in {cycleId}_${instanceId}_${instanceCounter} format.
final nextId = UnitId.nextId();
printDebug(nextId); // Prints ABC123_hello_6
```

---

**Part of Control Family**
Flutter Control:  https://pub.dev/packages/flutter_control
Control Core:     https://pub.dev/packages/control_core
Control Config:   https://pub.dev/packages/control_config
Localino:         https://pub.dev/packages/localino
Localino Live:    https://pub.dev/packages/localino_live
Localino Builder: https://pub.dev/packages/localino_builder
