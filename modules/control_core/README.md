![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/logo.png)
[![Structure](https://github.com/RomanBase/flutter_control/actions/workflows/dart.yml/badge.svg)](https://github.com/RomanBase/flutter_control)

---
`control_core` is the foundational library for Flutter and Dart projects, offering a robust set of tools for building scalable and maintainable applications. It simplifies state management, dependency injection, and event handling.

Key features include:
-   **Service Locator**: A powerful `ControlFactory` for managing dependencies and enabling easy testing and module swapping.
-   **Global Event System**: A `ControlBroadcast` mechanism for decoupled communication across your application.
-   **Observables**: A comprehensive system of `ControlObservable` and its specialized variants ([ActionControl], [FieldControl], [ListControl], [LoadingControl]) for reactive state management.
-   **Business Logic Models**: Structured base classes ([ControlModel], [BaseModel], [BaseControl]) that provide consistent lifecycle management and promote clean architecture.
-   **Lifecycle Management**: Fine-grained control over object initialization and disposal using `Initializable`, `Disposable`, and `DisposeHandler`.

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
    // Register singleton instances: objects available immediately.
    entries: {
      Logger: Logger(level: LogLevel.INFO),
    },
    // Register factories for lazy initialization: objects created on demand.
    factories: {
      ApiService: (_) => RestApiService(),
      UserRepository: (_) => DbUserRepository(Control.get<DatabaseConnection>()!),
    },
    // Use modules to organize your dependencies and their initialization.
    modules: [
      MyFeatureModule(), // Custom module bundling its own entries, factories, and init logic.
    ],
    // Perform asynchronous initialization tasks.
    initAsync: () async {
      // Example: Load initial configuration or warm up a service.
      await AppConfig.load();
      Control.get<ApiService>()?.initConnection();
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
// Retrieve an object by its type (most common).
final apiService = Control.get<ApiService>()!;

// Retrieve an object by a custom key (useful for multiple instances of the same type).
final userPreferences = Control.get<SharedPreferences>(key: 'user_prefs');

// Retrieve an object asynchronously (useful in async contexts, though get() is synchronous).
final config = await Control.getAsync<AppConfig>();
```

## Dynamic Registration

You can also register objects and factories dynamically after initialization.

```dart
// Register a new singleton instance at runtime.
Control.set<AnalyticsService>(value: FirebaseAnalyticsService());

// Register a new factory for a type at runtime.
Control.add<NotificationService>(init: (_) => PushNotificationService());
```

## LazyControl

The `LazyControl` mixin allows you to create objects that are lazily initialized and automatically removed from the factory when they are disposed.

```dart
/// The `LazyControl` mixin ensures that an object, when managed by `ControlFactory`,
/// is automatically removed from the factory's store when its `dispose()` method is called.
/// This is particularly useful for models with a distinct lifecycle, ensuring proper cleanup.
class UserSessionModel extends ControlModel with LazyControl {
  String? userId;

  UserSessionModel() {
    print('UserSessionModel created');
  }

  @override
  void init(Map args) {
    userId = args['userId'];
  }

  @override
  void dispose() {
    print('UserSessionModel disposed');
    super.dispose(); // This calls Control.remove(key: factoryKey)
  }
}

// Example Usage:
void setupSession() {
  Control.add<UserSessionModel>(init: (args) => UserSessionModel()..init(args));

  // UserSessionModel is not instantiated yet.

  final session = Control.get<UserSessionModel>(args: {'userId': 'user123'}); // Instantiated and stored.
  print('Current User ID: ${session?.userId}');

  session?.dispose(); // Model is disposed and automatically removed from ControlFactory.
  final disposedSession = Control.get<UserSessionModel>(); // Returns null, or a new instance if factory supports it.
}
```

## Dependency Injection vs. Property Injection

`control_core` supports common dependency injection patterns, allowing you to manage how dependencies are provided to your classes.

**Constructor Injection (Dependency Injection)**

This is the preferred method for explicit dependencies, making classes easier to test and understand.

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
      B: (_) => B(Control.get<A>()!), // B depends on A, injected via constructor.
    },
  );
}
```

**Property Injection**

Useful for optional dependencies or when dependencies are only needed in specific methods, or for models that are themselves dependencies.

```dart
class C {
  // Lazily retrieve dependency when needed.
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

The `control_core` library provides a global event system for decoupled communication using `BroadcastProvider`. This static utility class offers a simple interface to the underlying `ControlBroadcast`, enabling components to send and receive data or events without direct dependencies.

The system supports two main types of communication:
-   **Object Broadcasting**: Sending data objects to interested listeners.
-   **Event Broadcasting**: Sending simple notifications without a data payload.

### Subscribing to Events

You can subscribe to events using the `BroadcastProvider.subscribe()` and `BroadcastProvider.subscribeEvent()` methods.

```dart
// Subscribe to an object broadcast with a specific key and expected type.
// The listener receives the value when broadcasted.
BroadcastProvider.subscribe<int>('cart_item_count', (count) {
  print('Cart item count updated: $count');
});

// Subscribe to a simple event broadcast with a specific key.
// The listener is notified without receiving a specific value.
BroadcastProvider.subscribeEvent('user_logged_out', () {
  print('User has logged out.');
});

// You can also subscribe using only the type (e.g., if the type acts as the key).
BroadcastProvider.subscribeOf<User>( (user) {
    print('User data changed: ${user?.name}');
});
```

### Broadcasting Events

You can broadcast events using the `BroadcastProvider.broadcast()` and `BroadcastProvider.broadcastEvent()` methods.

```dart
// Broadcast a data object. Listeners subscribed to 'cart_item_count' of type int will be notified.
BroadcastProvider.broadcast<int>(key: 'cart_item_count', value: 5);

// Broadcast a simple event. Listeners subscribed to 'user_logged_out' will be notified.
BroadcastProvider.broadcastEvent(key: 'user_logged_out');

// Broadcast an object using its type as the key.
BroadcastProvider.broadcast<User>(value: User(name: 'Jane Doe'));
```

---

# Observables

`control_core` provides a powerful set of tools for managing state and reacting to changes. At the core of this system are `ControlObservable` and `ControlSubscription`, which provide the foundation for more specialized classes like `ActionControl` and `FieldControl`.

## ActionControl

`ActionControl` is a versatile implementation of `ControlObservable` offering specialized behaviors for managing and reacting to value changes. It's suitable for simple reactive properties.

Key variants:
-   **`ActionControl.single<T>(value)`**: An observable that enforces a single active subscriber. When a new listener subscribes, any previous listener is automatically unsubscribed.
-   **`ActionControl.broadcast<T>(value)`**: A standard observable allowing multiple listeners to subscribe and react to changes.
-   **`ActionControl.empty<T?>()`**: A variant that explicitly handles nullable types, enabling clear state management for potentially absent values.
-   **`ActionControl.leaf<T extends ObservableBase>(model)`**: Creates a bubbling observable. It wraps another `ObservableBase` (the "leaf") and propagates its notifications upwards to this `ActionControl`'s listeners.
-   **`ActionControl.provider<T>(key)`**: An observable that automatically synchronizes its value with the global `BroadcastProvider`. Changes to this control's value are broadcasted globally, and incoming broadcasts update the control's value.

Example:
```dart
// Create a broadcast ActionControl with an initial integer value.
final counter = ActionControl.broadcast<int>(0);

// Subscribe to the counter. The callback receives the updated value.
counter.subscribe((value) => print('Counter value: $value'));

// Increment the counter. This triggers all subscribed listeners.
counter.value++; // Output: Counter value: 1
counter.value = 5; // Output: Counter value: 5
```

## FieldControl

`FieldControl` is a more robust, stream-centric observable built upon Dart's `Stream` and `StreamController`. It's particularly well-suited for complex reactive scenarios, handling asynchronous data flows, and integrating with external streams (e.g., from network requests or user input fields).

Key capabilities:
-   **Stream Integration**: Can be created from or subscribe to existing `Stream`s.
-   **Asynchronous Operations**: Easily manages values from `Future`s.
-   **Sinks**: Provides a `sink` to programmatically add new values to its internal stream.

Example:
```dart
// Create a FieldControl with an initial integer value.
final inputField = FieldControl<String>('initial text');

// Subscribe to changes in the input field.
inputField.subscribe((text) => print('Input changed: $text'));

// Simulate user input. This updates the value and notifies subscribers.
inputField.setValue('Hello World'); // Output: Input changed: Hello World

// You can also feed values via its sink.
inputField.sink.add('New text from sink'); // Output: Input changed: New text from sink
```

## ObservableComponent

The `ObservableComponent<T>` and `NotifierComponent` mixins enhance any `ControlModel` by giving it reactive capabilities.

-   **`ObservableComponent<T>`**: Transforms a `ControlModel` into an `ObservableValue<T?>`. The model can hold a value of type `T` and notify listeners when that value changes.
-   **`NotifierComponent`**: Transforms a `ControlModel` into an `ObservableChannel`. The model can send simple notifications (events without data) to listeners.

Example with `ObservableComponent`:
```dart
class CounterModel extends BaseModel with ObservableComponent<int> {
  CounterModel() {
    value = 0; // Set initial value
  }

  void increment() {
    // Updating 'value' automatically notifies all subscribers.
    value = (value ?? 0) + 1;
  }
}

// In a UI widget:
// final counterModel = Control.get<CounterModel>();
// counterModel.subscribe((count) => print('Counter UI update: $count'));
// counterModel.increment();
```

Example with `NotifierComponent`:
```dart
class FormSubmitModel extends BaseModel with NotifierComponent {
  void submitForm() {
    // ... form processing logic ...
    notify(); // Signal that the form has been submitted (event without data).
  }
}

// In a UI widget or service:
// final formModel = Control.get<FormSubmitModel>();
// formModel.subscribe(() => showSnackBar('Form submitted successfully!'));
// formModel.submitForm();
```

## ControlSubscription

A `ControlSubscription` represents an active listener to an observable. It's returned when you call `subscribe()` on an observable and provides powerful methods for managing the listener's behavior and lifecycle.

Key features of `ControlSubscription`:
-   **`filter(Predicate<T> predicate)`**: Only notify the subscriber if the new value passes the given test.
-   **`until(Predicate<T> predicate)`**: Automatically cancel the subscription once a value passes the given test.
-   **`once()`**: Cancel the subscription after the first notification.
-   **`cancel()`**: Manually stop the subscription.

Example:
```dart
final gameScore = ActionControl.broadcast<int>(0);

// Subscribe to gameScore, but only react if the score is even,
// and automatically unsubscribe once the score reaches 10 or more.
final scoreSubscription = gameScore
    .subscribe((score) => print('Even score: $score'))
    .filter((score) => score % 2 == 0)
    .until((score) => score >= 10);

gameScore.value = 1; // No output (filtered)
gameScore.value = 2; // Output: Even score: 2
gameScore.value = 7; // No output (filtered)
gameScore.value = 10; // Output: Even score: 10 (and subscription is now cancelled)
gameScore.value = 12; // No output (subscription already cancelled)
```
---

# Business Logic

The `control_core` library provides a structured approach to implementing business logic through a hierarchy of model classes: `ControlModel`, `BaseModel`, and `BaseControl`. These classes standardize lifecycle management, initialization, and disposal.

-   **`ControlModel`**: The foundational abstract class for all business logic components. It integrates `Initializable` and `DisposeHandler` to provide a consistent lifecycle with `init()`, `mount()`, and `dispose()` methods. All other models extend this class.
-   **`BaseModel`**: A lightweight concrete implementation of `ControlModel`, ideal for simpler, more focused business logic. By default, `BaseModel` utilizes a "soft dispose" strategy (via `preferSoftDispose`), meaning it might not be automatically fully disposed by `ControlFactory` and often requires manual disposal when truly finished.
-   **`BaseControl`**: A robust concrete implementation of `ControlModel`, designed for complex business logic components like feature controllers or long-lived services. It enforces that its `onInit()` method is called only once (via `preventMultiInit`), making it suitable for managing significant state or orchestrating multiple services. `BaseControl` instances are typically managed by the `ControlFactory`.

## Lifecycle Management: Initializable and DisposeHandler

`control_core` provides sophisticated mechanisms for managing object lifecycles, ensuring proper initialization and resource cleanup. These are primarily facilitated by the `Initializable` interface and the `DisposeHandler` mixin, both integrated into `ControlModel` and its derivatives.

### Initializable

The `Initializable` interface defines a standard `init(Map args)` method, offering a consistent way to configure objects after their construction. This is especially useful for:
-   **Late Property Injection**: Providing dependencies or configuration values post-construction.
-   **Complex Setup**: Performing setup that requires the object to be fully constructed first.

Example:
```dart
class MyService implements Initializable {
  late String apiKey;

  @override
  void init(Map args) {
    apiKey = args['api_key'] as String;
    print('MyService initialized with API Key: $apiKey');
  }
}

void main() {
  Control.add<MyService>(init: (args) => MyService()..init(args));
  final service = Control.get<MyService>(args: {'api_key': '12345'});
  // Output: MyService initialized with API Key: 12345
}
```

### Disposable and DisposeHandler

The `Disposable` mixin marks an object as requiring resource cleanup via its `dispose()` method. The `DisposeHandler` mixin extends this by providing fine-grained control over when and how `dispose()` is called, offering "soft" and "hard" disposal strategies.

Key properties of `DisposeHandler`:
-   **`preventDispose`**: If `true`, calls to `requestDispose()` are ignored, requiring manual `dispose()`.
-   **`preferSoftDispose`**: If `true`, `requestDispose()` will call `softDispose()` instead of the full `dispose()`. `softDispose()` is for partial cleanup (e.g., stopping active operations) when an object might be reused.
-   **`requestDispose(Object? sender)`**: The primary method to initiate disposal, respecting `preventDispose` and `preferSoftDispose` settings.

Example:
```dart
class MyResource with DisposeHandler {
  bool _isOpen = false;

  void open() {
    _isOpen = true;
    print('Resource opened');
  }

  @override
  void softDispose() {
    print('Resource softly disposed (e.g., paused)');
    // Cancel subscriptions, pause operations, but don't fully destroy.
  }

  @override
  void dispose() {
    super.dispose(); // Always call super.dispose() for mixins.
    _isOpen = false;
    print('Resource fully disposed (e.g., closed connections)');
  }
}

void main() {
  final resource = MyResource();
  resource.open();

  resource.preferSoftDispose = true; // Set to prefer soft dispose
  resource.requestDispose(); // Output: Resource softly disposed (e.g., paused)

  resource.preferSoftDispose = false; // Set to prefer full dispose
  resource.requestDispose(); // Output: Resource fully disposed (e.g., closed connections)
}
```

---

# Utilities

`control_core` includes a set of utility classes and extensions to simplify common development tasks.

## FutureBlock

`FutureBlock` is a powerful utility for managing delayed and asynchronous operations, functioning similarly to a debounce mechanism. It allows you to schedule a `VoidCallback` to run after a specified duration, with the ability to re-trigger or cancel the delay.

Key features:
-   **Debouncing**: Prevents a function from being called too frequently by resetting the timer with each new call.
-   **Cancellable**: The scheduled action can be explicitly canceled before execution.
-   **Re-triggerable**: The delay can be extended or restarted.

Example:
```dart
final searchDebouncer = FutureBlock();

void onSearchQueryChanged(String query) {
  print('Typing: $query');
  searchDebouncer.delayed(Duration(milliseconds: 300), () {
    print('Searching for: $query'); // This runs 300ms after typing stops.
  });
}

onSearchQueryChanged('apple');
onSearchQueryChanged('app'); // This cancels the previous 'apple' delay.
onSearchQueryChanged('apply'); // This cancels the previous 'app' delay.
// Output after 300ms of inactivity: Searching for: apply

// --- Other functionalities ---
// block.trigger(); // Immediately executes the scheduled callback and stops the timer.
// block.cancel();  // Cancels any pending delayed execution.

// You can extend an existing FutureBlock (the parent is canceled).
// final anotherBlock = FutureBlock.extend(parent: searchDebouncer, duration: Duration(seconds: 1));
```

## ControlArgs

`ControlArgs` is a versatile utility class for storing, passing, and retrieving arguments in a type-safe and flexible manner. It's especially useful in conjunction with `ControlFactory` for initializing objects with dynamic configurations or dependencies.

Key features:
-   **Dynamic Input**: Can parse arguments from `Map`s, `Iterable`s, or single objects.
-   **Type-Safe Retrieval**: Easily retrieve values by type or by key.
-   **Combination**: Merge multiple `ControlArgs` instances.

Example:
```dart
// Create ControlArgs from various sources.
final args = ControlArgs.of({
  'userName': 'Jane Doe',
  'age': 30,
  MyService: MyService(), // Can store actual objects by their type.
  'settings': {'theme': 'dark'},
});

// Retrieve values by key and type.
final userName = args.get<String>(key: 'userName'); // 'Jane Doe'
final userAge = args.get<int>(key: 'age');         // 30
final myService = args.get<MyService>();          // Instance of MyService
final theme = args.get<Map>(key: 'settings')?['theme']; // 'dark'

// Add a new value (type-inferred or with explicit key).
args.add<bool>(key: 'isAdmin', value: true);

// Check if a key exists.
if (args.containsKey('isAdmin')) {
  print('Is Admin: ${args.get<bool>(key: 'isAdmin')}'); // Is Admin: true
}
```

## UnitId

`UnitId` is a utility for generating unique identifiers (UIDs) within the application, often used for tracking instances or events. It allows for custom prefixes and counters.

Example:
```dart
// Configure UnitId with a custom instance ID and a persistent counter.
UnitId.instanceId = 'APP_INSTANCE_ALPHA';
// Assume LocalPrefs is a persistent storage utility
// UnitId.instanceCounter = LocalPrefs.get('unit_id_counter', defaultValue: 0);
// UnitId.onChanged = () => LocalPrefs.set('unit_id_counter', UnitId.instanceCounter);

// Generate a unique ID. The format is typically {timestamp_base36}_{instanceId}_{counter}.
final firstId = UnitId.nextId();
print('Generated ID: $firstId'); // Example: 1A2B3C_APP_INSTANCE_ALPHA_1

final secondId = UnitId.nextId();
print('Generated ID: $secondId'); // Example: 1A2B3D_APP_INSTANCE_ALPHA_2
```

---

**Part of Control Family: https://github.com/RomanBase/flutter_control**
* Flutter Control:  https://pub.dev/packages/flutter_control
* Control Core:     https://pub.dev/packages/control_core
* Control Config:   https://pub.dev/packages/control_config
* Localino:         https://pub.dev/packages/localino
* Localino Live:    https://pub.dev/packages/localino_live
* Localino Builder: https://pub.dev/packages/localino_builder