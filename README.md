# Flutter Control

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/logo.png)

[![Build Status](https://github.com/RomanBase/flutter_control/actions/workflows/dart.yml/badge.svg)](https://github.com/RomanBase/flutter_control/actions/workflows/dart.yml)
[![Pub Version](https://img.shields.io/pub/v/flutter_control)](https://pub.dev/packages/flutter_control)

A comprehensive framework for building robust and scalable Flutter applications. Flutter Control streamlines state management, dependency injection, and navigation, providing a structured approach to application development.

## Features

-   **Modular State Management**: Manage both global application state and granular widget-level state effectively.
-   **Powerful Dependency Injection**: Built-in Service Locator with Factory and Singleton patterns for efficient dependency management.
-   **Flexible Navigation & Routing**: Define routes, manage transitions, and pass arguments seamlessly across your app.
-   **Reactive Programming**: Observable patterns ([ActionControl], [FieldControl]) integrated with UI builders for dynamic updates.
-   **Global Event System**: A robust broadcast mechanism for application-wide event communication.
-   **Theming & Localization**: Integrated support for dynamic themes and internationalization (via [Localino]).
-   **Modular Architecture**: Organize your app into independent modules for better maintainability and scalability.

## Getting Started

### 1. Add Dependency

Add `flutter_control` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_control: # Use the latest version from pub.dev
```

### 2. Basic Setup

Initialize the core framework in your `main.dart` and wrap your app with `ControlRoot`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_control/control.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Control Framework
  await Control.initControl(
    // Register your app's dependencies (models, services)
    entries: {
      MyService: MyService(),
    },
    initializers: {
      MyControl: (args) => MyControl(Control.get<MyService>(args)!),
    },
    // Register modules (e.g., LocalinoModule for localization)
    modules: [
      // LocalinoModule(LocalinoLive.options()), // If using localino_live
    ],
    // Perform asynchronous initialization tasks
    initAsync: () async {
      // await loadAppConfig();
    },
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 2. Wrap your app with ControlRoot
    return ControlRoot(
      // Configure global theme management
      theme: MaterialThemeConfig(
        themes: {
          Brightness.light: () => ThemeData.light(),
          Brightness.dark: () => ThemeData.dark(),
          'custom': () => ThemeData.dark().copyWith(primaryColor: Colors.purple),
        }
      ),
      // Define application states (e.g., init, auth, main)
      states: [
        AppState.init.build(builder: (_) => LoadingPage()),
        AppState.main.build(
          builder: (_) => HomePage(),
          transition: CrossTransition.fade(), // Optional transition between states
        ),
        // Add more states like AppState.auth, AppState.onboarding
      ],
      // The main app builder, usually MaterialApp or CupertinoApp
      builder: (context, home) => MaterialApp(
        title: 'Flutter Control App', // Replace with your app title
        theme: context.themeConfig?.value, // Dynamic theme from ControlRoot
        home: home, // The currently active AppState widget
        // Localization setup (if using Localino)
        // locale: LocalinoProvider.instance.currentLocale,
        // supportedLocales: LocalinoProvider.delegate.supportedLocales(),
        // localizationsDelegates: [
        //   LocalinoProvider.delegate,
        //   GlobalMaterialLocalizations.delegate,
        //   GlobalWidgetsLocalizations.delegate,
        //   GlobalCupertinoLocalizations.delegate,
        // ],
        // Route generation
        onGenerateRoute: (settings) => context.generateRoute(settings, root: () => MaterialPageRoute(builder: (_) => home)),
      ),
    );
  }
}

// Example pages
class LoadingPage extends BaseControlWidget {
  @override
  Widget build(CoreContext context) {
    // Navigate to main state after some loading
    Future.delayed(Duration(seconds: 2), () => ControlScope.root.setMainState());
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class HomePage extends BaseControlWidget {
  @override
  Widget build(CoreContext context) {
    return Scaffold(appBar: AppBar(title: Text('Home Page')), body: Center(child: Text('Welcome!')));
  }
}

// Example service and control
class MyService {}
class MyControl extends ControlModel {
  final MyService _service;
  MyControl(this._service);
}
```

## Core Concepts

### Control Framework Core

-   **`Control`**: The central static class for initializing and accessing the framework's core functionalities, including the `ControlFactory`.
-   **`ControlFactory`**: A powerful Service Locator and Dependency Injection container. It manages the lifecycle and instantiation of your app's services, models, and other dependencies, making them accessible throughout the application.
-   **`ControlModule`**: Enables modularity by encapsulating related dependencies and configurations. Modules are loaded by `ControlFactory` to register their services.

### Application Lifecycle & State

-   **`ControlRoot`**: The root widget of your application that orchestrates global state management, including:
    -   **`AppState`**: Defines distinct states of your application (e.g., `init`, `auth`, `main`). `ControlRoot` transitions between these states, allowing you to easily switch between different UI flows.
    -   **`ThemeConfig`**: Manages dynamic theming (light, dark, custom) and persists user theme preferences.

## State Management

### Widget-Level State

-   **`CoreWidget`**: The base `StatefulWidget` for all control widgets, creating a `CoreContext` which acts as a powerful element for local dependency injection and state management within the widget tree.
-   **`ControlWidget`**: A flexible base class for widgets that manage one or more [ControlModel]s, providing robust lifecycle management and automatic UI updates.
-   **`SingleControlWidget<T>`**: Optimized for widgets that primarily depend on a single [ControlModel] of type `T`, automatically resolving and providing it.
-   **`ControllableWidget<T>`**: A reactive widget that rebuilds automatically when a provided `control` (single or list of observables) notifies of changes.

### Models

-   **`ControlModel`**: The base class for defining your application's business logic and state. Models are framework-aware and can interact with the dependency injection and event systems.
-   **`BaseControl`**: An extended version of `ControlModel` with additional functionalities, typically used for more complex and robust logic components.
-   **`BaseModel`**: A lightweight variant of `ControlModel`, suitable for simpler logic components.

### Reactive Observables

-   **`ControlObservable`**: An abstraction for various observable types ([ActionControl], [FieldControl], [ValueListenable], [Stream], [Future]), providing a unified way to subscribe to changes.
-   **`ActionControl`**: A lightweight observable primarily used for notifying listeners about value changes. Supports single, broadcast, and empty variants.
    ```dart
    final counter = ActionControl.broadcast<int>(0); // Create an observable int

    // ... later in your UI ...
    ControlBuilder<int>( // Rebuilds automatically when `counter` changes
      control: counter,
      builder: (context, value) => Text('Count: $value'),
    );

    // To update the value:
    // counter.value++;
    ```
-   **`FieldControl`**: A more robust observable built around Dart Streams, ideal for complex data flows, validation, and transformations. Comes with specialized variants like `StringControl`, `NumberControl`, and `ListControl`.
    ```dart
    final usernameField = FieldControl<String>('', validator: (value) => value.isEmpty ? 'Required' : null);

    // ... later in your UI ...
    FieldBuilder<String>( // Rebuilds and handles validation messages
      control: usernameField,
      builder: (context, value) => TextField(
        controller: usernameField,
        decoration: InputDecoration(errorText: usernameField.error),
      ),
    );

    // To update the value:
    // usernameField.value = 'new_username';
    ```
-   **`ControlBuilder` / `ControlBuilderGroup`**: Widgets that automatically subscribe to `ControlObservable`s (or a list of them) and rebuild their children when changes are notified.

## Navigation & Routing

-   **`ControlRoute`**: Defines application routes with associated widgets, dynamic path parameters, custom transitions, and navigation arguments. Routes are typically registered centrally.
-   **`RouteStore`**: A central repository for all defined `ControlRoute`s, making them discoverable and reusable throughout the application.
-   **`RouteNavigator`**: An abstract interface for performing navigation actions (push, pop, replace). `ControlNavigator` is the default Flutter implementation.
-   **`RouteHandler`**: Binds a `ControlRoute` to a `RouteNavigator`, providing a fluent API to open routes with specific configurations.

    ```dart
    // 1. Define and register routes in Control.initControl or RoutingModule
    await Control.initControl(
      modules: [
        RoutingModule([
          ControlRoute.build<UserPage>(builder: (_) => UserPage()),
          ControlRoute.build(identifier: 'profile_edit', builder: (_) => ProfileEditPage())
             .viaTransition(CrossTransition.slide()), // Custom transition
        ]),
      ],
    );

    // 2. Navigate from any BuildContext
    class MyWidget extends BaseControlWidget {
      @override
      Widget build(CoreContext context) {
        return ElevatedButton(
          onPressed: () {
            // Navigate to UserPage using its type
            context.routeOf<UserPage>()?.openRoute();
            
            // Navigate to 'profile_edit' using its identifier and arguments
            context.routeOf(identifier: 'profile_edit')?.openRoute(args: {'userId': 123});
          },
          child: Text('Go to User Page'),
        );
      }
    }
    ```

## Global Event System

-   **`ControlBroadcast`**: Provides an application-wide event stream. You can subscribe to specific event types/keys and broadcast data across your app, decoupled from the widget tree.
-   **`BroadcastProvider`**: A utility class to easily `subscribe` to and `broadcast` events via the `ControlBroadcast` instance managed by `ControlFactory`.

    ```dart
    // Subscribe to an event
    BroadcastProvider.subscribe<int>('on_counter_update', (value) {
      print('Counter updated to: $value');
    });

    // Broadcast an event
    BroadcastProvider.broadcast('on_counter_update', 10);
    ```

## Ecosystem

Flutter Control is part of a larger ecosystem of packages designed to enhance your development workflow:

-   **[Localino](https://pub.dev/packages/localino)**: Comprehensive JSON-based localization solution for Flutter, offering dynamic locale management and string formatting.
-   **[Localino Live](https://pub.dev/packages/localino_live)**: Enables Over-The-Air (OTA) translation updates by connecting `Localino` to the [localino.app](https://localino.app) backend.
-   **[Localino Builder](https://pub.dev/packages/localino_builder)**: Code generation for `Localino`, providing type-safe access to translations and automated setup.

## Examples

Explore the [Flutter Control Examples](https://github.com/RomanBase/flutter_control/tree/master/example) repository for practical demonstrations and more complex solutions using this library.